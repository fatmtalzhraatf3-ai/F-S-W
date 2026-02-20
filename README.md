<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>محاكي الأرض الواقعي</title>
<style>
body { font-family: Arial; text-align:center; background:#f0f0f0; margin:0; padding:0;}
h1 { margin-top:20px; color:#2c3e50; }
input, button { margin:10px; padding:10px; font-size:16px; }
#render3D { width: 90%; height: 500px; margin: 20px auto; border:2px solid #333; }
#downloadLink { display:block; margin-top:15px; font-weight:bold; color:blue; }
</style>
</head>
<body>

<h1>محاكي الأرض الواقعي - Simple Terrain Simulator</h1>

<input type="file" id="fileInput" accept=".xlsx"/>
<button onclick="processExcel()">رفع وتحليل البيانات</button>
<a id="downloadLink" style="display:none">تحميل النتائج</a>

<div id="render3D"></div>

<!-- Libraries -->
<script src="https://cdn.jsdelivr.net/npm/xlsx/dist/xlsx.full.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r152/three.min.js"></script>

<script>
let terrainData = [];

function processExcel() {
    const input = document.getElementById('fileInput');
    if(!input.files[0]) { alert("اختر ملف Excel"); return; }
    const reader = new FileReader();
    reader.onload = function(e){
        const data = new Uint8Array(e.target.result);
        const workbook = XLSX.read(data, {type:'array'});
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];
        const jsonData = XLSX.utils.sheet_to_json(sheet);
        
        terrainData = jsonData.map(row => ({
            x: row['X'] || 0,
            y: row['Y'] || 0,
            elevation: row['Elevation'] || 0
        }));

        alert("تم قراءة البيانات بنجاح!");
        create3DTerrain();
        generateExcelOutput(jsonData);
    };
    reader.readAsArrayBuffer(input.files[0]);
}

function generateExcelOutput(data){
    // هنا نحسب Cut & Fill بشكل مبسط
    data.forEach(row => row['Cut/Fill'] = Math.round(row['Elevation'] - 100)); // مثال
    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Results");
    XLSX.writeFile(wb, "output.xlsx");
    document.getElementById('downloadLink').style.display = 'block';
}

function create3DTerrain(){
    // إزالة أي 3D سابق
    const container = document.getElementById('render3D');
    container.innerHTML = '';

    // إعداد المشهد والكاميرا
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xbfd1e5);
    const camera = new THREE.PerspectiveCamera(45, container.clientWidth/container.clientHeight, 0.1, 1000);
    camera.position.set(50,50,50);
    camera.lookAt(0,0,0);

    const renderer = new THREE.WebGLRenderer({antialias:true});
    renderer.setSize(container.clientWidth, container.clientHeight);
    container.appendChild(renderer.domElement);

    // أرضية بسيطة
    const geometry = new THREE.PlaneGeometry(100, 100, 49, 49);
    geometry.rotateX(-Math.PI/2);

    // وضع ارتفاعات من البيانات
    for(let i=0; i<terrainData.length && i<geometry.attributes.position.count; i++){
        geometry.attributes.position.setY(i, terrainData[i].elevation/2); // تصغير الارتفاع
    }
    geometry.computeVertexNormals();

    const material = new THREE.MeshStandardMaterial({color:0x228B22, wireframe:false, flatShading:true});
    const terrain = new THREE.Mesh(geometry, material);
    scene.add(terrain);

    // إضاءة
    const ambientLight = new THREE.AmbientLight(0xffffff,0.6);
    scene.add(ambientLight);
    const dirLight = new THREE.DirectionalLight(0xffffff,0.8);
    dirLight.position.set(50,50,50);
    scene.add(dirLight);

    // تحريك الكاميرا
    const controls = new THREE.OrbitControls(camera, renderer.domElement);

    function animate(){
        requestAnimationFrame(animate);
        renderer.render(scene, camera);
    }
    animate();
}
</script>
<script src="https://threejs.org/examples/js/controls/OrbitControls.js"></script>
</body>
</html>
