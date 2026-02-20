<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>المشروع المساحي الذكي - ملاعب 3D واقعية</title>
<style>
body { font-family: Arial, sans-serif; background:#eef2f3; text-align:center; margin:0; padding:0;}
h1 { color:#2c3e50; margin:20px 0; }
input, button { margin:10px; padding:10px; font-size:16px; }
#results { margin:20px auto; width:95%; max-width:900px; border-collapse: collapse;}
#results th, #results td { border:1px solid #333; padding:8px; }
#results th { background:#2c3e50; color:white; }
#render3D { width:95%; height:600px; margin:20px auto; border:2px solid #333; }
#downloadLink { display:block; margin-top:15px; font-weight:bold; color:blue; text-decoration:none; }
</style>
</head>
<body>
<h1>المشروع المساحي الذكي - ملاعب 3D واقعية</h1>
<input type="file" id="fileInput" accept=".xlsx">
<button onclick="processFile()">رفع الملف وحساب المشروع</button>
<a id="downloadLink" style="display:none" download="output.xlsx">تحميل النتائج</a>

<table id="results" style="display:none;">
<thead>
<tr><th>رقم النقطة</th><th>الارتفاع</th><th>مساحة</th><th>الحفر/الردم</th></tr>
</thead>
<tbody></tbody>
</table>

<div id="render3D"></div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
<script src="https://threejs.org/examples/js/controls/OrbitControls.js"></script>

<script>
function processFile() {
    const input = document.getElementById('fileInput');
    if(!input.files[0]) { alert('اختر ملف Excel أولاً'); return; }
    const reader = new FileReader();
    reader.onload = function(e) {
        const data = new Uint8Array(e.target.result);
        const workbook = XLSX.read(data, {type:'array'});
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];
        const json = XLSX.utils.sheet_to_json(sheet);

        json.forEach(row => {
            const elevation = parseFloat(row['Elevation'] || row['الارتفاع'] || 0);
            const area = parseFloat(row['Area'] || row['مساحة'] || 1);
            row['Cut/Fill'] = (elevation - 1.5) * area;
        });

        displayTable(json);
        generate3D(json);
        createDownload(json);
    };
    reader.readAsArrayBuffer(input.files[0]);
}

function displayTable(data) {
    const tbody = document.querySelector('#results tbody');
    tbody.innerHTML = '';
    data.forEach(row => {
        const tr = document.createElement('tr');
        tr.innerHTML = `<td>${row['Point']||row['رقم النقطة']}</td>
                        <td>${row['Elevation']||row['الارتفاع']}</td>
                        <td>${row['Area']||row['مساحة']}</td>
                        <td>${row['Cut/Fill'].toFixed(2)}</td>`;
        tbody.appendChild(tr);
    });
    document.getElementById('results').style.display='table';
}

function createDownload(data) {
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Results');
    const wbout = XLSX.write(wb, {bookType:'xlsx', type:'array'});
    const blob = new Blob([wbout], {type:'application/octet-stream'});
    const url = URL.createObjectURL(blob);
    const link = document.getElementById('downloadLink');
    link.href = url;
    link.style.display='block';
}

function generate3D(data) {
    document.getElementById('render3D').innerHTML='';
    const width = document.getElementById('render3D').clientWidth;
    const height = 600;
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xbfd1e5);

    const camera = new THREE.PerspectiveCamera(45,width/height,0.1,1000);
    camera.position.set(25,20,25);
    camera.lookAt(0,0,0);

    const renderer = new THREE.WebGLRenderer({antialias:true});
    renderer.setSize(width,height);
    document.getElementById('render3D').appendChild(renderer.domElement);

    const light = new THREE.DirectionalLight(0xffffff,1);
    light.position.set(30,50,30);
    scene.add(light);
    scene.add(new THREE.AmbientLight(0x404040));

    // أرضية العشب الأساسية
    const groundGeo = new THREE.BoxGeometry(30,0.2,20);
    const groundMat = new THREE.MeshLambertMaterial({color:0x28a745});
    const ground = new THREE.Mesh(groundGeo, groundMat);
    scene.add(ground);

    // ملاعب متعددة
    // كرة القدم
    const footballGeo = new THREE.BoxGeometry(20,0.1,12);
    const footballMat = new THREE.MeshLambertMaterial({color:0x228B22});
    const football = new THREE.Mesh(footballGeo, footballMat);
    football.position.set(0,0.1,0);
    scene.add(football);

    const lineMat = new THREE.LineBasicMaterial({color:0xffffff});
    const linePoints = [
        new THREE.Vector3(-10,0.11,-6), new THREE.Vector3(10,0.11,-6),
        new THREE.Vector3(10,0.11,6), new THREE.Vector3(-10,0.11,6),
        new THREE.Vector3(-10,0.11,-6)
    ];
    const lineGeo = new THREE.BufferGeometry().setFromPoints(linePoints);
    scene.add(new THREE.Line(lineGeo,lineMat));

    // ملعب تنس
    const tennisGeo = new THREE.BoxGeometry(6,0.05,3);
    const tennisMat = new THREE.MeshLambertMaterial({color:0xfff0a0});
    const tennisCourt = new THREE.Mesh(tennisGeo, tennisMat);
    tennisCourt.position.set(0,0.12,8);
    scene.add(tennisCourt);

    // حمام سباحة
    const poolGeo = new THREE.BoxGeometry(5,0.1,3);
    const poolMat = new THREE.MeshLambertMaterial({color:0x1ca3ec});
    const pool = new THREE.Mesh(poolGeo,poolMat);
    pool.position.set(-10,0.15,5);
    scene.add(pool);

    // أشجار حول الملعب
    const treeGeo = new THREE.ConeGeometry(0.5,2,8);
    const treeMat = new THREE.MeshLambertMaterial({color:0x006400});
    for(let i=-12;i<=12;i+=6){
        for(let j=-10;j<=10;j+=5){
            const tree = new THREE.Mesh(treeGeo,treeMat);
            tree.position.set(i,1,j);
            scene.add(tree);
        }
    }

    // نقاط البيانات
    data.forEach((row,i)=>{
        const elev = parseFloat(row['Elevation']||row['الارتفاع']||0);
        const geometry = new THREE.SphereGeometry(0.3,16,16);
        const material = new THREE.MeshLambertMaterial({color:0xff0000});
        const sphere = new THREE.Mesh(geometry,material);
        sphere.position.set((i%10)-5, elev/10, Math.floor(i/10)-2);
        scene.add(sphere);
    });

    // Render loop
    function animate() { requestAnimationFrame(animate); renderer.render(scene,camera); }
    animate();

    const controls = new THREE.OrbitControls(camera, renderer.domElement);
}
</script>
</body>
</html>
