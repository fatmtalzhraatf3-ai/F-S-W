<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>المشروع المساحي الذكي - ملعب 3D</title>
<style>
body { font-family: Arial, sans-serif; background:#eef2f3; text-align:center; margin:0; padding:0;}
h1 { color:#2c3e50; margin:20px 0; }
input, button { margin:10px; padding:10px; font-size:16px; }
#results { margin:20px auto; width:90%; max-width:800px; border-collapse: collapse;}
#results th, #results td { border:1px solid #333; padding:8px; }
#results th { background:#2c3e50; color:white; }
#render3D { width:90%; height:500px; margin:20px auto; border:2px solid #333; }
#downloadLink { display:block; margin-top:15px; font-weight:bold; color:blue; text-decoration:none; }
</style>
</head>
<body>
<h1>المشروع المساحي الذكي - ملعب 3D</h1>
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

        // حساب Cut & Fill لكل نقطة
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
    const height = 500;
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xbfd1e5);

    const camera = new THREE.PerspectiveCamera(45,width/height,0.1,1000);
    camera.position.set(0,20,30);
    camera.lookAt(0,0,0);

    const renderer = new THREE.WebGLRenderer({antialias:true});
    renderer.setSize(width,height);
    document.getElementById('render3D').appendChild(renderer.domElement);

    // الإضاءة
    const light = new THREE.DirectionalLight(0xffffff,1);
    light.position.set(20,40,20);
    scene.add(light);
    scene.add(new THREE.AmbientLight(0x404040));

    // أرضية الملعب (عشب)
    const groundGeo = new THREE.BoxGeometry(20,0.2,12);
    const groundMat = new THREE.MeshLambertMaterial({color:0x28a745});
    const ground = new THREE.Mesh(groundGeo, groundMat);
    scene.add(ground);

    // خطوط كرة القدم
    const lineMat = new THREE.LineBasicMaterial({color:0xffffff});
    const linePoints = [
        new THREE.Vector3(-10,0.11,-6), new THREE.Vector3(10,0.11,-6),
        new THREE.Vector3(10,0.11,6), new THREE.Vector3(-10,0.11,6),
        new THREE.Vector3(-10,0.11,-6)
    ];
    const lineGeo = new THREE.BufferGeometry().setFromPoints(linePoints);
    const line = new THREE.Line(lineGeo,lineMat);
    scene.add(line);

    // ملعب تنس
    const tennisGeo = new THREE.BoxGeometry(6,0.05,3);
    const tennisMat = new THREE.MeshLambertMaterial({color:0xfff0a0});
    const tennisCourt = new THREE.Mesh(tennisGeo, tennisMat);
    tennisCourt.position.set(0,0.12,4.5);
    scene.add(tennisCourt);

    // حمام سباحة
    const poolGeo = new THREE.BoxGeometry(4,0.1,2);
    const poolMat = new THREE.MeshLambertMaterial({color:0x1ca3ec});
    const pool = new THREE.Mesh(poolGeo,poolMat);
    pool.position.set(-6,0.15,3);
    scene.add(pool);

    // نقاط البيانات من جدول الميزانية
    data.forEach((row,i) => {
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

    // تحريك الكاميرا بالماوس
    const controls = new THREE.OrbitControls(camera, renderer.domElement);
}
</script>
<script src="https://threejs.org/examples/js/controls/OrbitControls.js"></script>
</body>
</html>
