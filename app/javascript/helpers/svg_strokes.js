// app/javascript/helpers/svg_strokes.js
import { angleBetweenPoints, distance } from "helpers/svg_utils"
const DASH_PATTERN = '12,8'
export const PATH_WIDTH = 8
const WAVE_FREQUENCY = 6

export function applyStrokeStyle(pathElement, options) {
  // Clear previous styling
  pathElement.removeAttribute('stroke-dasharray')
  const originalD = pathElement.getAttribute('d') || ''
  
  // Store original path data if not already stored
  if (!pathElement.dataset.originalD) {
    pathElement.dataset.originalD = originalD
  }

  switch (options.style) {
    case 'dashed':
      pathElement.setAttribute('stroke-dasharray', DASH_PATTERN)
      pathElement.setAttribute('d', pathElement.dataset.originalD)
      break

    case 'double':
      pathElement.setAttribute('d', createDoublePath(pathElement.dataset.originalD, PATH_WIDTH * 1.2))
      break

    case 'wavy':
      pathElement.setAttribute('d', createWavyPath(pathElement.dataset.originalD, PATH_WIDTH * 1.8, WAVE_FREQUENCY))
      break

    default:  // solid
      pathElement.setAttribute('d', pathElement.dataset.originalD)
      break
  }
}

function createDoublePath(d, spacing) {
  const commands = d.match(/[A-Z][^A-Z]*/gi) || []
  const path1 = []
  const path2 = []

  commands.forEach(cmd => {
    const type = cmd[0]
    const coords = cmd.slice(1).trim().split(/[\s,]+/).map(Number)
    const newCoords1 = []
    const newCoords2 = []

    for (let i = 0; i < coords.length; i += 2) {
      const x = coords[i]
      const y = coords[i+1]

      if (i > 0) {
        const px = coords[i-2]
        const py = coords[i-1]
        const angle = angleBetweenPoints(px, py, x, y)
        const offsetX = Math.cos(angle + Math.PI/2) * spacing/2
        const offsetY = Math.sin(angle + Math.PI/2) * spacing/2

        newCoords1.push(x + offsetX, y + offsetY)
        newCoords2.push(x - offsetX, y - offsetY)
      } else {
        newCoords1.push(x + spacing/2, y + spacing/2)
        newCoords2.push(x - spacing/2, y - spacing/2)
      }
    }

    path1.push(`${type}${newCoords1.join(' ')}`)
    path2.push(`${type}${newCoords2.join(' ')}`)
  })

  return `${path1.join(' ')} ${path2.reverse().join(' ')} Z`
}

function createWavyPath(d, amplitude) {
  const commands = d.match(/[A-Z][^A-Z]*/gi) || []
  const wavePoints = []

  commands.forEach(cmd => {
    const type = cmd[0]
    const coords = cmd.slice(1).trim().split(/[\s,]+/).map(Number)

    for (let i = 0; i < coords.length; i += 2) {
      const x = coords[i]
      const y = coords[i+1]

      if (i > 0) {
        const px = coords[i-2]
        const py = coords[i-1]
        const dist = distance(px, py, x, y)
        const angle = angleBetweenPoints(px, py, x, y)
        const steps = Math.max(3, Math.floor(dist / 10))

        for (let s = 1; s <= steps; s++) {
          const t = s / steps
          const bx = px + (x - px) * t
          const by = py + (y - py) * t
          const offset = amplitude * Math.sin(t * Math.PI * 4) // 4 waves per segment
          const wx = bx + offset * Math.cos(angle + Math.PI/2)
          const wy = by + offset * Math.sin(angle + Math.PI/2)

          wavePoints.push(`${s === 1 && i === 2 ? 'M' : 'L'} ${wx} ${wy}`)
        }
      } else {
        wavePoints.push(`${type} ${x} ${y}`)
      }
    }
  })

  return wavePoints.join(' ')
}