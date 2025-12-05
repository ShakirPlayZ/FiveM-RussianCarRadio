// Blyad Radio - JavaScript Logic (xsound version)
// xsound übernimmt das Audio-Streaming, NUI nur für UI

let currentVolume = 50;
let isPlaying = false;

// DOM Elements
const radioContainer = document.getElementById('radio-container');
const radioBody = document.getElementById('radioBody');
const radioContent = document.getElementById('radioContent');
const closeBtn = document.getElementById('closeBtn');
const playBtn = document.getElementById('playBtn');
const stopBtn = document.getElementById('stopBtn');
const volumeSlider = document.getElementById('volumeSlider');
const volumeFill = document.getElementById('volumeFill');
const volumeValue = document.getElementById('volumeValue');
const volUpBtn = document.getElementById('volUp');
const volDownBtn = document.getElementById('volDown');
const statusText = document.getElementById('statusText');

// Update Display
function updateDisplay() {
    if (isPlaying) {
        statusText.textContent = 'Ein';
        statusText.style.color = '#00ff00';
    } else {
        statusText.textContent = 'Aus';
        statusText.style.color = '#ff3333';
    }
}

// Update Now Playing Display
function updateNowPlaying(songTitle) {
    const nowPlayingText = document.getElementById('nowPlayingText');
    if (nowPlayingText) {
        if (songTitle && songTitle !== "" && songTitle !== "Lädt...") {
            nowPlayingText.textContent = songTitle;
            nowPlayingText.style.color = '#00ff00';
        } else {
            nowPlayingText.textContent = isPlaying ? 'Lädt...' : 'Kein Song';
            nowPlayingText.style.color = isPlaying ? '#ffaa00' : '#666';
        }
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
    }).catch(err => console.error('Volume error:', err));
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
    }).catch(err => console.error('Close error:', err));
}

// Event Listeners
closeBtn.addEventListener('click', closeRadio);

playBtn.addEventListener('click', () => {
    console.log('🎮 [NUI] Play Button clicked!');
    console.log('🎮 [NUI] Sending to:', `https://${GetParentResourceName()}/play`);
    
    fetch(`https://${GetParentResourceName()}/play`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    })
    .then(resp => {
        console.log('✅ [NUI] Play request sent successfully');
        // Versuche JSON zu parsen, aber fange Fehler ab
        return resp.text(); // Hole als Text statt JSON
    })
    .then(text => {
        console.log('✅ [NUI] Response:', text);
        // Versuche als JSON zu parsen
        try {
            const data = JSON.parse(text);
            console.log('✅ [NUI] Parsed JSON:', data);
        } catch(e) {
            console.log('⚠️ [NUI] Response ist kein JSON, aber OK');
        }
    })
    .catch(err => {
        console.error('❌ [NUI] Play request failed:', err);
    });
});

stopBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/pause`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    }).catch(err => console.error('Stop error:', err));
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
        case 'updateNowPlaying':
            if (data.songTitle !== undefined) {
                updateNowPlaying(data.songTitle);
            }
            break;
    }
});

function GetParentResourceName() {
    try {
        // FiveM NUI URLs: cfx-nui-RESOURCENAME
        const hostname = window.location.hostname;
        console.log('🔍 [DEBUG] Full hostname:', hostname);
        
        if (hostname.startsWith('cfx-nui-')) {
            const resourceName = hostname.replace('cfx-nui-', '');
            console.log('✅ [DEBUG] Extracted resource name:', resourceName);
            return resourceName;
        }
        
        return window.location.hostname.split('.')[0];
    } catch (e) {
        console.error('❌ [DEBUG] Error:', e);
        return 'blyad_radio';
    }
}

window.addEventListener('load', () => {
    updateDisplay();
    console.log('[Radio UI] xsound version loaded');
});
