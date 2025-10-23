// ✅ app/javascript/helpers/svg_buttons.js
export function disableButtons(buttons) {
  buttons.forEach(btn => { disableButton(btn) })
}

export function enableButtons(buttons) {
  buttons.forEach(btn => { enableButton(btn) })
}

export function highlightButton(button) {
  if (!button) return
  const activeClass = button.dataset.activeClass || 'bg-blue-400 text-white ring'
  button.classList.add(...activeClass.split(' '))
}

export function lowlightButton(button) {
  if (!button) return
  const activeClass = button.dataset.activeClass || ''
  button.classList.remove(...activeClass.split(' '))
}


// internal support functions
function disableButton(button) {
  const buttonObj = getButtonElement(button)
  if (buttonObj) {
    buttonObj.disabled = true
    buttonObj.classList.add('opacity-50', 'cursor-not-allowed')
  } else {
    console.error("Cannot disable button:", button)
  }
}

function enableButton(button) {
  const buttonObj = getButtonElement(button)
  if (buttonObj) {
    buttonObj.disabled = false
    buttonObj.classList.remove('opacity-50', 'cursor-not-allowed')
  } else {
    console.error("Cannot enable button:", button)
  }
}

function getButtonElement(tgt) {
  // If the target is already a button, return it
  if (tgt.tagName === 'BUTTON') return tgt

  // Otherwise, look for a button within the target
  const buttonEl = tgt.querySelector('button')
  if (buttonEl) {
    return buttonEl
  } else {
    console.error('Cannot find button for:', tgt)
  }
}