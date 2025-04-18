document.addEventListener('DOMContentLoaded', function() {
    // UI elemek
    const container = document.getElementById('autovezerlo-container');
    const closeButton = document.getElementById('close-button');
    const engineButton = document.getElementById('toggle-engine');
    const lightsButton = document.getElementById('toggle-lights');
    const doorButtons = document.querySelectorAll('.door-button');
    const windowButtons = document.querySelectorAll('.window-button');
    const engineStatus = document.getElementById('engine-status');
    const lightsStatus = document.getElementById('lights-status');
    const fuelLevel = document.getElementById('fuel-level');
    const fuelPercentage = document.getElementById('fuel-percentage');
    
    // Jármű státuszok
    let vehicleStatus = {
        engineOn: false,
        lightsOn: false,
        fuelLevel: 0,
        doors: [false, false, false, false, false, false], // 0-5 ajtók állapota
        windows: [false, false, false, false] // 0-3 ablakok állapota
    };
    
    // UI megnyitása
    function showUI() {
        container.classList.add('visible');
    }
    
    // UI bezárása
    function hideUI() {
        container.classList.remove('visible');
    }
    
    // Státuszok frissítése
    function updateUI() {
        // Motor státusz
        engineStatus.textContent = vehicleStatus.engineOn ? 'Bekapcsolva' : 'Kikapcsolva';
        engineStatus.classList.toggle('active', vehicleStatus.engineOn);
        engineButton.classList.toggle('active', vehicleStatus.engineOn);
        
        // Lámpák státusz
        lightsStatus.textContent = vehicleStatus.lightsOn ? 'Bekapcsolva' : 'Kikapcsolva';
        lightsStatus.classList.toggle('active', vehicleStatus.lightsOn);
        lightsButton.classList.toggle('active', vehicleStatus.lightsOn);
        
        // Üzemanyag szint
        const fuelPercent = typeof vehicleStatus.fuelLevel === 'number' ? vehicleStatus.fuelLevel : 0;
        fuelLevel.style.width = fuelPercent + '%';
        fuelPercentage.textContent = fuelPercent + '%';
        
        // Ajtók állapota
        doorButtons.forEach((button, index) => {
            if (index < vehicleStatus.doors.length) {
                button.classList.toggle('active', vehicleStatus.doors[index]);
            }
        });
        
        // Ablakok állapota
        windowButtons.forEach((button, index) => {
            if (index < vehicleStatus.windows.length) {
                button.classList.toggle('active', vehicleStatus.windows[index]);
            }
        });
    }
    
    // Általános fetch függvény a hibakezeléshez
    function fetchNUI(eventName, data = {}) {
        return fetch(`https://autovezerlo/${eventName}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify(data)
        })
        .then(resp => resp.json())
        .catch(error => console.error(`Hiba a '${eventName}' kérésnél:`, error));
    }
    
    // UI bezárása
    function closeUI() {
        fetchNUI('close');
    }
    
    // Event listeners
    closeButton.addEventListener('click', function() {
        closeUI();
    });
    
    engineButton.addEventListener('click', function() {
        fetchNUI('toggleEngine');
    });
    
    lightsButton.addEventListener('click', function() {
        fetchNUI('toggleLights');
    });
    
    doorButtons.forEach(button => {
        button.addEventListener('click', function() {
            const doorIndex = parseInt(this.dataset.door);
            fetchNUI('toggleDoor', { doorIndex });
        });
    });
    
    windowButtons.forEach(button => {
        button.addEventListener('click', function() {
            const windowIndex = parseInt(this.dataset.window);
            fetchNUI('toggleWindow', { windowIndex });
        });
    });
    
    // FiveM üzenetek kezelése
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === 'toggle') {
            if (data.status) {
                showUI();
            } else {
                hideUI();
            }
        }
        
        if (data.type === 'updateVehicleInfo') {
            // Jármű információk frissítése
            vehicleStatus.engineOn = Boolean(data.engineStatus);
            vehicleStatus.lightsOn = Boolean(data.lightsStatus);
            
            // Üzemanyagszint kezelése, biztosítva, hogy szám legyen
            vehicleStatus.fuelLevel = typeof data.fuelLevel === 'number' ? 
                Math.round(data.fuelLevel) : 0;
            
            // Ajtók és ablakok kezelése, biztosítva, hogy a hiányzó adatok ne okozzanak hibát
            if (Array.isArray(data.doors)) {
                vehicleStatus.doors = data.doors;
            }
            
            if (Array.isArray(data.windows)) {
                vehicleStatus.windows = data.windows;
            }
            
            // UI frissítése
            updateUI();
        }
    });
    
    // Billentyűzet figyelés az ESC gombhoz
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            closeUI();
        }
    });
}); 