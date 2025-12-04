// Blyad Radio - JavaScript Logic (xsound version)
// xsound übernimmt das Audio-Streaming, NUI nur für UI

let currentVolume = 50;
let isPlaying = false;
let isMinimized = false;

// DOM Elements
const radioContainer = document.getElementById('radio-container');
const radioBody = document.getElementById('radioBody');
const radioContent = document.getElementById('radioContent');
const closeBtn = document.getElementById('closeBtn');
const minimizeBtn = document.getElementById('minimizeBtn');
const playBtn = document.getElementById('playBtn');
const pauseBtn = document.getElementById('pauseBtn');
const volumeSlider = document.getElementById('volumeSlider');
const volumeFill = document.getElementById('volumeFill');
const volumeValue = document.getElementById('volumeValue');
const volUpBtn = document.getElementById('volUp');
const volDownBtn = document.getElementById('volDown');
const statusText = document.getElementById('statusText');

// Update Display
function updateDisplay() {
    if (isPlaying) {
        statusText.textContent = '播放';
        statusText.style.color = '#00ff00';
    } else {
        statusText.textContent = 'ВЫКЛ';
        statusText.style.color = '#ff3333';
    }
}

// Set Volume
function setVolume(volume) {
    currentVolume = Math.max(0, Math.min(100, volume));
    
    volumeSlider.value = currentVolume;
    volumeValue.textContent = currentVolume;
    volumeFill.style.width = currentVolume + '%';
    
    // Send to client
    fetch(`https://${GetParentResourceName()}/volumeChange`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            volume: currentVolume
        })
    });
}

// Close Radio
function closeRadio() {
    radioContainer.classList.add('closing');
    setTimeout(() => {
        radioContainer.classList.add('hidden');
        radioContainer.classList.remove('closing');
    }, 300);
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// Toggle Minimize
function toggleMinimize() {
    isMinimized = !isMinimized;
    if (isMinimized) {
        radioBody.classList.add('minimized');
        minimizeBtn.textContent = '▢';
    } else {
        radioBody.classList.remove('minimized');
        minimizeBtn.textContent = '−';
    }
}

// Event Listeners
closeBtn.addEventListener('click', closeRadio);
minimizeBtn.addEventListener('click', toggleMinimize);

playBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/play`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
});

pauseBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/pause`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
});

volumeSlider.addEventListener('input', (e) => setVolume(parseInt(e.target.value)));
volUpBtn.addEventListener('click', () => setVolume(currentVolume + 5));
volDownBtn.addEventListener('click', () => setVolume(currentVolume - 5));

document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape') closeRadio();
});

// Listen for messages from client
window.addEventListener('message', (event) => {
    const data = event.data;
    switch (data.action) {
        case 'openRadio':
            radioContainer.classList.remove('hidden');
            if (data.volume !== undefined) setVolume(data.volume);
            if (data.isPlaying !== undefined) isPlaying = data.isPlaying;
            updateDisplay();
            break;
        case 'closeRadio':
            radioContainer.classList.add('hidden');
            break;
        case 'updatePlaying':
            if (data.isPlaying !== undefined) {
                isPlaying = data.isPlaying;
                updateDisplay();
            }
            break;
        case 'setVolume':
            if (data.volume !== undefined) setVolume(data.volume);
            break;
    }
});

function GetParentResourceName() {
    try {
        return window.location.hostname.split('.')[0];
    } catch (e) {
        return 'blyad_radio';
    }
}

window.addEventListener('load', () => {
    updateDisplay();
    console.log('[Radio UI] xsound version loaded');
});
