// app/javascript/controllers/diagram_editor_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "output", "courtField", "deleteButton"]
  static values = {
    court: String,
    courtMap: Object
  }

  connect() {
    console.log("Diagram editor connected")
    this.setCourtImage(this.courtValue)

    this.attackerCount = 11
    this.defenderCount = 1

    // Variables de dragging
    this.selectedElement = null;
    this.draggedElement = null
    this.offset = { x: 0, y: 0 }

    // Usamos pointer events y nos aseguramos de enlazar con 'bind' el contexto
    this.startDragBound = this.startDrag.bind(this)
    this.doDragBound = this.doDrag.bind(this)
    this.stopDragBound = this.stopDrag.bind(this)

    this.canvasTarget.addEventListener('click', this.selectElement.bind(this));
    this.canvasTarget.addEventListener("click", this.handleCanvasClick.bind(this));
    this.canvasTarget.addEventListener("pointerdown", this.startDragBound)
    window.addEventListener("pointermove", this.doDragBound)
    window.addEventListener("pointerup", this.stopDragBound)
    this.resizeBound = () => this.setCourtImage(this.courtValue)
    window.addEventListener("resize", this.resizeBound)

    if (this.hasCourtFieldTarget) {
      this.courtFieldTarget.value = this.courtValue
    } 
  }

  disconnect(){
    this.canvasTarget.removeEventListener('click', this.selectElementBound);
    window.removeEventListener("pointerdown", this.startDragBound)
    window.removeEventListener("pointermove", this.doDragBound)
    window.removeEventListener("pointerup", this.stopDragBound)
    window.removeEventListener("resize", this.resizeBound)
  }

  // Métodos de cambio de cancha (sin modificaciones)
  switchCourt(event) {
    this.courtValue = event.target.value
    this.setCourtImage(this.courtValue)
  }

  setCourtImage(courtKey) {
    const svg = this.canvasTarget
    const path =  this.courtMapValue[this.courtValue]
    if (!path) {
      console.warn("Court path not found for:", courtKey)
      return
    }
    
    // Cambiamos la imagen
    console.log("Setting court to:", path)
    const image = svg.querySelector("image")
    image.setAttribute("href", path)
    if (this.hasCourtFieldTarget) {
      this.courtFieldTarget.value = courtKey
    }    
    // Creamos un objeto Image para cargarla y leer su tamaño
    const img = new window.Image()
    img.onload = () => {
      this.zoomToFit(svg, img)
    }
    img.src = path
  }

  serialize() {
    const cloned = this.canvasTarget.cloneNode(true)
    const bg = cloned.querySelector("image")
    if (bg) bg.remove()
    const svgContent = new XMLSerializer().serializeToString(cloned)
    this.outputTarget.value = svgContent
  }

  // Métodos de inserción (sin cambios)
  addAttacker() {
    const { width, height } = this.currentViewBox();
    // Definimos el radio como un % del ancho del canvas
    const radius = width * 0.03;        // 2% del ancho
    // Posición inicial también en % (ejemplo: 10% desde izquierda, 10% desde arriba)
    const x0 = width * 0.10;
    const y0 = height * 0.10;
  
    const group = this.createGroup(x0, y0);
    const circle = this.createCircle(0, 0, radius, "white", "black");
    // Ajustamos el tamaño de texto al 1.5× el radio
    const text = this.createText(0, 5, this.attackerCount, radius * 1.5, "black");
  
    group.appendChild(circle);
    group.appendChild(text);
    this.canvasTarget.appendChild(group);
    this.attackerCount++;
    this.serialize();
  }

  addDefender() {
    const { width, height } = this.currentViewBox();
    // Altura del triángulo: 5% del alto
    const triHeight = height * 0.06;
    const x0 = width * 0.15;
    const y0 = height * 0.10;
  
    const group = this.createGroup(x0, y0);
    const triangle = this.createTriangle(0, 0, triHeight, "lightgrey", "black");
    // Font-size aprox. 60% de la altura
    const text = this.createText(0, 15, this.defenderCount, triHeight * 0.6, "black");
  
    group.appendChild(triangle);
    group.appendChild(text);
    this.canvasTarget.appendChild(group);
    this.defenderCount++;
    this.serialize();  
  }
  
  addBall() {
    const { width, height } = this.currentViewBox();
    // Radio de balón: 1.5% del ancho
    const r = width * 0.01;
    const x0 = width * 0.20;
    const y0 = height * 0.10;
  
    const group = this.createGroup(x0, y0);
    const ball = this.createCircle(0, 0, r, "black", "black");
    group.appendChild(ball);
    this.canvasTarget.appendChild(group);
    this.serialize();
  }  

  addCone() {
    const { width, height } = this.currentViewBox();
    // Tamaño del cono: base 3% del ancho, altura 5% del alto
    const base = width * 0.03;
    const heightC = height * 0.05;
    const x0 = width * 0.2;
    const y0 = height * 0.3;
  
    // Creamos el path dinámico según base/altura
    const d = `
      M ${-base} ${heightC/2}
      Q 0 ${-heightC} ${base} ${heightC/2}
      Z
    `;
    const cone = document.createElementNS("http://www.w3.org/2000/svg", "path");
    cone.setAttribute("d", d);
    cone.setAttribute("fill", "red");
  
    const group = this.createGroup(x0, y0);
    group.appendChild(cone);
    this.canvasTarget.appendChild(group);
    this.serialize();
  }

  deleteSelected() {
    if (!this.selectedElement) return;
    // Animación de desvanecimiento opcional
    this.selectedElement.classList.add('opacity-0', 'transition-opacity', 'duration-300');
    // Tras la animación, lo eliminamos
    setTimeout(() => {
      this.selectedElement.remove();                             // 
      this.selectedElement = null;
      this.deleteButtonTarget.disabled = true;
      this.serialize();
    }, 300);
  }

  selectElement(event) {
    // 1. Quita indicador previo
    const prev = this.selectedElement?.querySelector(".selection-indicator");
    if (prev) prev.remove();
  
    // 2. Busca el group más cercano
    const group = event.target.closest("g.draggable");
    if (!group) return;
  
    // 3. Almacena la referencia
    this.selectedElement = group;
    this.deleteButtonTarget.disabled = false;
  
    // 4. Crea y añade el indicador DENTRO del grupo
    const bbox = group.getBBox();
    // Coordenadas relativas al grupo: esquina superior izquierda
    const indicator = document.createElementNS("http://www.w3.org/2000/svg", "circle");
    indicator.setAttribute("cx", bbox.x < 0 ? 0 : bbox.x);       // o simplemente 0
    indicator.setAttribute("cy", bbox.y < 0 ? 0 : 0);           // y=0 en local
    indicator.setAttribute("r", 5);
    indicator.setAttribute("fill", "red");
    indicator.setAttribute("class", "selection-indicator");
  
    // Si el group tiene transform, mejor crear un sub-grupo sin transform:
    // const markerGroup = document.createElementNS(..., "g");
    // markerGroup.setAttribute("transform", group.getAttribute("transform"));
    // markerGroup.appendChild(indicator);
    // this.canvasTarget.appendChild(markerGroup);
  
    group.appendChild(indicator);
  }
  
  handleCanvasClick(event) {
    const group = event.target.closest("g.draggable");
    if (!group) {
      // Eliminar indicador de selección existente
      const existingIndicator = this.canvasTarget.querySelector(".selection-indicator");
      if (existingIndicator) {
        existingIndicator.remove();
      }
      this.selectedElement = null;
      this.deleteButtonTarget.disabled = true;
    }
  }  

  startDrag(event) {
    // Buscamos el elemento más cercano con clase "draggable" dentro de un <g>
    const target = event.target.closest("g.draggable")
    if (!target) return

    this.draggedElement = target

    // Obtener un objeto punto en coordenadas SVG
    const svg = this.canvasTarget
    const pt = svg.createSVGPoint()
    pt.x = event.clientX
    pt.y = event.clientY
    // Convertimos a coordenadas del SVG
    const cursorPt = pt.matrixTransform(svg.getScreenCTM().inverse())

    // Obtenemos la transformación actual del elemento
    let transform = this.draggedElement.transform.baseVal.consolidate()
    let matrix = transform ? transform.matrix : svg.createSVGMatrix()

    // Calculamos el offset relativo entre la posición del cursor y el punto de la transformación
    this.offset = {
      x: cursorPt.x - matrix.e,
      y: cursorPt.y - matrix.f
    }

    event.preventDefault()
  }

  doDrag(event) {
    if (!this.draggedElement) return

    const svg = this.canvasTarget
    const pt = svg.createSVGPoint()
    pt.x = event.clientX
    pt.y = event.clientY
    const cursorPt = pt.matrixTransform(svg.getScreenCTM().inverse())

    // Calculamos la nueva posición restando el offset obtenido al inicio
    const newX = cursorPt.x - this.offset.x
    const newY = cursorPt.y - this.offset.y

    this.draggedElement.setAttribute("transform", `translate(${newX}, ${newY})`)

    // Actualizamos el SVG serializado
    this.serialize()
    event.preventDefault()
  }

  stopDrag(event) {
    if (this.draggedElement) {
      // Se ha soltado el elemento; actualizamos la serialización y reiniciamos.
      this.serialize()
    }
    this.draggedElement = null
  }

  // line drawing
  startDrawShot() {
    this.currentDrawType = "shot";
    this.initDrawing();
  }
  
  startDrawPass() {
    this.currentDrawType = "pass";
    this.initDrawing();
  }
  
  startDrawMoveNoBall() {
    this.currentDrawType = "moveNoBall";
    this.initDrawing();
  }
  
  startDrawMoveWithBall() {
    this.currentDrawType = "moveWithBall";
    this.initDrawing();
  }
  
  // Lógica compartida:
  initDrawing() {
    // Aquí puedes, por ejemplo:
    // 1. Cambiar el cursor (this.canvasTarget.style.cursor = "crosshair")
    // 2. Añadir listener para pointerdown/pointermove/pointerup que dibuje la línea según this.currentDrawType
    // 3. Al finalizar el dibujo, serializar y resetear el modo drawing.
  }

  // --- Helpers ---
  createGroup(x, y) {
    const group = document.createElementNS("http://www.w3.org/2000/svg", "g")
    group.setAttribute("transform", `translate(${x}, ${y})`)
    group.classList.add("draggable")
    group.style.cursor = "grab"
    return group
  }

  createCircle(cx, cy, r, fill, stroke) {
    const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle")
    circle.setAttribute("cx", cx)
    circle.setAttribute("cy", cy)
    circle.setAttribute("r", r)
    circle.setAttribute("fill", fill)
    circle.setAttribute("stroke", stroke)
    return circle
  }

  createText(x, y, content, size, color) {
    const text = document.createElementNS("http://www.w3.org/2000/svg", "text")
    text.setAttribute("x", x)
    text.setAttribute("y", y)
    text.setAttribute("text-anchor", "middle")
    text.setAttribute("dominant-baseline", "middle")
    text.setAttribute("font-size", size)
    text.setAttribute("font-weight", "bold")
    text.setAttribute("fill", color)
    text.textContent = content
    return text
  }
  
  createTriangle(cx, cy, height, fill, stroke) {
    const halfBase = height / 2
    const points = [
      `${cx},${cy - height / 2}`,         // vértice superior
      `${cx - halfBase},${cy + height / 2}`, // vértice inferior izquierdo
      `${cx + halfBase},${cy + height / 2}`  // vértice inferior derecho
    ].join(" ")
  
    const triangle = document.createElementNS("http://www.w3.org/2000/svg", "polygon")
    triangle.setAttribute("points", points)
    triangle.setAttribute("fill", fill)
    triangle.setAttribute("stroke", stroke)
    return triangle
  }

  currentViewBox() {
    const vb = this.canvasTarget.viewBox.baseVal;
    return { width: vb.width, height: vb.height };
  }

  zoomToFit(svg, img) {
    // Obtener dimensiones del contenido SVG
    const w = img.naturalWidth
    const h = img.naturalHeight
    
    // Obtener dimensiones del tamaño máximo
    const maxWidth = window.innerWidth * 0.9; // 90% del ancho de la ventana
    const maxHeight = window.innerHeight * 0.75; // 75% del alto de la ventana
    
    // Calcular la escala necesaria para que el contenido se ajuste al contenedor
    const widthRatio = maxWidth / w;
    const heightRatio = maxHeight / h;
    const scale = Math.min(widthRatio, heightRatio);
    
    //console.log(`limits: ${maxWidth} x ${maxHeight}`)
    //console.log(`img: ${w} x ${h}`)
    //console.log("scale:", scale)
    
    // Calcular nuevas dimensiones del viewBox
    const newWidth = Math.min(w * scale, maxWidth)
    const newHeight = Math.min(h * scale, maxHeight)
    //console.log(`new container: ${newWidth} x ${newHeight}`)

    // Establecer el nuevo viewBox centrado
    svg.setAttribute("viewBox", `0 0 ${w} ${h}`)
    svg.setAttribute("width", newWidth)
    svg.setAttribute("height", newHeight)
    svg.setAttribute("preserveAspectRatio", "xMidYMid meet")
  }
}
