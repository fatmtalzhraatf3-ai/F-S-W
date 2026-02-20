<!DOCTYPE html>
<html lang="ar">
<head>
<meta charset="UTF-8">
<title>المشروع المساحي المتكامل</title>
<style>
body { font-family: Arial, sans-serif; background:#eef2f3; text-align:center; margin:0; padding:0; }
header { background:#2c3e50; color:white; padding:20px; font-size:24px; }
.container { padding:20px; max-width:1200px; margin:auto; }
input, button { margin:10px; padding:10px; font-size:16px; }
#downloadLink { display:block; margin:15px; font-weight:bold; color:blue; }
#map { width:100%; height:400px; margin:20px 0; border:2px solid #333; }
#render3D { width:100%; height:500px; border:2px solid #333; margin:20px 0; }
table { margin:auto; border-collapse: collapse; width:90%; }
th, td { border:1px solid #333; padding:8px; text-align:center; }
th { background:#34495e; color:white; }
</style>
</head>
<body>
<header>المشروع المساحي الذكي</header>
<div class="container">
<h2>رفع جدول الميزانية الشبكية</h2>
<input type="file" id="fileInput" accept=".xlsx">
<button onclick="uploadFile()">اعرض المشروع</button>
<a id="downloadLink" style="display:none">تحميل النتائج</a>

<div id="tableContainer"></div>
<div id="map"></div>
<div id="render3D"></div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.151.3/build/three.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/three@0.151.3/examples/js/controls/OrbitControls.js"></script>
<script async src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY&callback=initMap"></script>

<script>
let data = [];

function uploadFile() {
    const input = document.getElementById('fileInput');
    const file = input.files[0];
    if(!file) { alert("اختر ملف Excel"); return; }

    const reader = new FileReader();
    reader.onload = function(e) {
        const dataArray = new Uint8Array(e.target.result);
        const workbook = XLSX.read(dataArray, {type:'array'});
        const firstSheet = workbook.Sheets[workbook.SheetNames[0]];
        data = XLSX.utils.sheet_to_json(firstSheet, {defval:""});
        displayTable(data);
        render3DScene(data);
        document.getElementById("downloadLink").style.display="none";
    };
    reader.readAsArrayBuffer(file);
}

function displayTable(data) {
    let html = "<h3>بيانات الميزانية الشبكية</h3><table><tr>";
    for(let key in data[0]) html += `<th>${key}</th>`;
    html += "</tr>";
    data.forEach(row => {
        html += "<tr>";
        for(let key in row) html += `<td>${row[key]}</td>`;
        html += "</tr>";
    });
    html += "</table>";
    document.getElementById("tableContainer").innerHTML = html;
}

// 3D Visualization
let scene, camera, renderer, controls;
function render3DScene(data) {
    const container = document.getElementById("render3D");
    container.innerHTML = "";
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0xbfd1e5);

    camera = new THREE.PerspectiveCamera(75, container.clientWidth/container.clientHeight, 0.1, 1000);
    camera.position.set(50,50,50);

    renderer = new THREE.WebGLRenderer({antialias:true});
    renderer.setSize(container.clientWidth, container.clientHeight);
    container.appendChild(renderer.domElement);

    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;

    // Light
    const light = new THREE.DirectionalLight(0xffffff,1);
    light.position.set(50,50,50);
    scene.add(light);
    scene.add(new THREE.AmbientLight(0x404040));

    // Ground
    const ground = new THREE.Mesh(
        new THREE.PlaneGeometry(100,100,10,10),
        new THREE.MeshPhongMaterial({color:0x2ecc71, side:THREE.DoubleSide})
    );
    ground.rotation.x = -Math.PI/2;
    scene.add(ground);

    // Plot points from Excel
    const geometry = new THREE.SphereGeometry(0.5,16,16);
    const material = new THREE.MeshPhongMaterial({color:0xe74c3c});
    data.forEach(row => {
        const x = parseFloat(row["Distance"]) || 0;
        const y = parseFloat(row["Elevation"]) || 0;
        const z = parseFloat(row["Angle"]) || 0;
        const sphere = new THREE.Mesh(geometry, material);
        sphere.position.set(x, y, z);
        scene.add(sphere);
    });

    animate();
}

function animate() {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
}

// Google Map
function initMap() {
    const center = { lat: 26.1648, lng: 32.7168 }; 
    const map = new google.maps.Map(document.getElementById("map"), { zoom:16, center:center });
}

</script>
</body>
</html>
