<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Survey Project Complete</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r152/three.min.js"></script>
<style>
body { font-family: Arial, sans-serif; background:#f0f8ff; text-align:center; margin:0; padding:0; }
h1 { color:#1f3b4d; margin:20px; }
input, select, button { margin:10px; padding:10px; font-size:16px; border-radius:5px; border:1px solid #333; cursor:pointer; }
table { margin:20px auto; border-collapse:collapse; width:90%; max-width:800px; box-shadow:0 0 10px rgba(0,0,0,0.2);}
th, td { border:1px solid #333; padding:8px 12px; text-align:center; }
th { background:#1f3b4d; color:white; }
tr:nth-child(even) { background:#e6f2ff; }
tr:hover { background:#cce6ff; }
#map, #render3D { width:80%; height:400px; margin:20px auto; border:2px solid #333; border-radius:10px; }
</style>
</head>
<body>
<h1>Survey Project Complete</h1>

<label for="projectType">Choose Project Type:</label>
<select id="projectType" onchange="updateMapIcon(); update3DModel();">
  <option value="Stadium">Stadium</option>
  <option value="School">School</option>
  <option value="Building">Building</option>
</select>

<br>
<input type="file" id="fileInput" accept=".xlsx,.xls" multiple>
<button onclick="loadFiles()">Load Project Data</button>

<div id="map"></div>
<div id="tableContainer"></div>
<div id="render3D"></div>

<script>
// ====== Google Maps ======
let map, marker;
const defaultCenter = { lat: 26.1648, lng: 32.7168 };

function initMap() {
  map = new google.maps.Map(document.getElementById("map"), { zoom: 16, center: defaultCenter });
  marker = new google.maps.Marker({ position: defaultCenter, map: map, title: "Project Location", draggable: true });
  marker.addListener('dragend', function() {
    const pos = marker.getPosition();
    console.log("New Location: ", pos.lat(), pos.lng());
  });
}

function updateMapIcon() {
  const type = document.getElementById('projectType').value;
  let iconColor = type === "Stadium" ? "http://maps.google.com/mapfiles/ms/icons/green-dot.png" :
                  type === "School" ? "http://maps.google.com/mapfiles/ms/icons/blue-dot.png" :
                  "http://maps.google.com/mapfiles/ms/icons/red-dot.png";
  marker.setIcon(iconColor);
}

// ====== Excel Merge, Traverse & Cut/Fill ======
let mergedData = [];

function loadFiles() {
  const files = document.getElementById('fileInput').files;
  if(files.length === 0) { alert("Please select files"); return; }
  
  mergedData = [];
  let filesLoaded = 0;

  Array.from(files).forEach(file => {
    const reader = new FileReader();
    reader.onload = function(e) {
      const data = new Uint8Array(e.target.result);
      const workbook = XLSX.read(data, {type:'array'});
      const sheet = workbook.Sheets[workbook.SheetNames[0]];
      const jsonData = XLSX.utils.sheet_to_json(sheet, {header:1});
      processExcelData(jsonData);
      filesLoaded++;
      if(filesLoaded === files.length) displayTable(mergedData);
    };
    reader.readAsArrayBuffer(file);
  });
}

function processExcelData(data){
  const headers = data[0];
  for(let i=1; i<data.length; i++){
    const row = data[i];
    let obj = {};
    headers.forEach((h, idx) => { obj[h] = row[idx]; });

    // تصحيح الترافيرس: Angle, Distance
    obj["Corrected Angle"] = obj.Angle || 0;
    obj["Corrected Distance"] = obj.Distance || 0;

    // حساب Cut & Fill
    obj["Cut/Fill"] = calculateCutFill(obj);

    mergedData.push(obj);
  }
}

function calculateCutFill(row){
  if(!row.Elevation) return 0;
  const cut = Math.max(...mergedData.map(r=>r.Elevation || 0)) - row.Elevation;
  const fill = row.Elevation - Math.min(...mergedData.map(r=>r.Elevation || 0));
  return (cut>fill? cut : fill).toFixed(2);
}

function displayTable(data){
  const container = document.getElementById('tableContainer');
  container.innerHTML = '';
  const table = document.createElement('table');

  if(data.length ===0) return;
  const headers = Object.keys(data[0]);
  const trHead = document.createElement('tr');
  headers.forEach(h => { const th = document.createElement('th'); th.innerText = h; trHead.appendChild(th); });
  table.appendChild(trHead);

  data.forEach(row => {
    const tr = document.createElement('tr');
    headers.forEach(h => { const td = document.createElement('td'); td.innerText = row[h] || ""; tr.appendChild(td); });
    table.appendChild(tr);
  });

  container.appendChild(table);
}

// ====== Three.js 3D Visualization ======
let scene, camera, renderer, model;

function init3D() {
  const container = document.getElementById('render3D');
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0xe6f2ff);

  camera = new THREE.PerspectiveCamera(45, container.clientWidth/container.clientHeight, 0.1, 1000);
  camera.position.set(0, 50, 100);

  renderer = new THREE.WebGLRenderer({ antialias:true });
  renderer.setSize(container.clientWidth, container.clientHeight);
  container.appendChild(renderer.domElement);

  const light = new THREE.DirectionalLight(0xffffff, 1);
  light.position.set(50, 100, 50);
  scene.add(light);

  const ambient = new THREE.AmbientLight(0x888888);
  scene.add(ambient);

  add3DModel();
  animate();
}

function add3DModel() {
  if(model) scene.remove(model);

  const type = document.getElementById('projectType').value;
  let geometry = type==="Stadium"? new THREE.CylinderGeometry(20,20,5,32):
                 type==="School"? new THREE.BoxGeometry(30,10,20):
                 new THREE.BoxGeometry(20,20,20);

  const material = new THREE.MeshPhongMaterial({ color: type==="Stadium"?0x00ff00:type==="School"?0x0000ff:0xff0000, shininess:50 });
  model = new THREE.Mesh(geometry, material);
  model.position.y = geometry.parameters.height/2;
  scene.add(model);
}

function update3DModel() { add3DModel(); }

function animate() {
  requestAnimationFrame(animate);
  if(model) model.rotation.y += 0.01;
  renderer.render(scene, camera);
}

window.addEventListener('load', ()=>{ init3D(); });
</script>

<script async src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY&callback=initMap"></script>
</body>
</html>
