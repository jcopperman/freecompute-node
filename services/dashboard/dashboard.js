// Dashboard functionality for Free Compute Node
const API_URL = `${window.location.protocol}//${window.location.host}`;
let API_KEY = localStorage.getItem('routerApiKey') || null;

// Show/hide elements based on authentication status
function updateAuthVisibility() {
  const authElements = document.querySelectorAll('.auth-required');
  const noAuthElements = document.querySelectorAll('.no-auth');
  
  if (API_KEY) {
    authElements.forEach(el => el.style.display = 'block');
    noAuthElements.forEach(el => el.style.display = 'none');
    fetchNodeInfo();
  } else {
    authElements.forEach(el => el.style.display = 'none');
    noAuthElements.forEach(el => el.style.display = 'block');
  }
}

// Handle API key submission
function submitApiKey() {
  const keyInput = document.getElementById('api-key-input');
  if (keyInput.value.trim()) {
    API_KEY = keyInput.value.trim();
    localStorage.setItem('routerApiKey', API_KEY);
    updateAuthVisibility();
  }
}

// Clear API key
function clearApiKey() {
  API_KEY = null;
  localStorage.removeItem('routerApiKey');
  updateAuthVisibility();
}

// Fetch node information
async function fetchNodeInfo() {
  try {
    const response = await fetch(`${API_URL}/api/system/status`, {
      method: 'GET',
      headers: {
        'X-API-Key': API_KEY
      }
    });
    
    if (!response.ok) {
      if (response.status === 401) {
        clearApiKey(); // Invalid API key
        return;
      }
      throw new Error(`API error: ${response.status}`);
    }
    
    const data = await response.json();
    updateDashboard(data);
  } catch (error) {
    console.error('Failed to fetch node info:', error);
    showError(error.message);
  }
}

// Update dashboard with fetched data
function updateDashboard(data) {
  // Update node info
  document.getElementById('node-name').textContent = data.node.name;
  document.getElementById('node-role').textContent = data.node.role;
  document.getElementById('node-uptime').textContent = new Date(data.node.uptime).toLocaleString();
  document.getElementById('last-updated').textContent = new Date(data.node.lastUpdated).toLocaleString();
  
  // Update resources
  if (data.node.resources) {
    document.getElementById('cpu-usage').textContent = data.node.resources.cpu !== null ? `${data.node.resources.cpu}%` : 'N/A';
    document.getElementById('memory-usage').textContent = data.node.resources.memory !== null ? `${data.node.resources.memory}%` : 'N/A';
    document.getElementById('disk-usage').textContent = data.node.resources.disk !== null ? `${data.node.resources.disk}%` : 'N/A';
  }
  
  // Update services
  const servicesContainer = document.getElementById('services-container');
  servicesContainer.innerHTML = ''; // Clear existing services
  
  // Add service cards for each service
  for (const [id, service] of Object.entries(data.services)) {
    const card = createServiceCard(
      id.charAt(0).toUpperCase() + id.slice(1), // Capitalize first letter
      service.status,
      service.port,
      getServiceUrl(id, service)
    );
    servicesContainer.appendChild(card);
  }
  
  // Update mesh info
  document.getElementById('mesh-node-count').textContent = data.mesh.nodeCount;
  document.getElementById('mesh-last-synced').textContent = data.mesh.lastSynced ? new Date(data.mesh.lastSynced).toLocaleString() : 'Never';
}

// Create service card element
function createServiceCard(name, status, port, url) {
  const card = document.createElement('div');
  card.className = 'card';
  
  const isActive = status === 'active';
  const statusClass = isActive ? 'status-active' : 'status-inactive';
  const statusText = isActive ? 'Active' : 'Inactive';
  
  card.innerHTML = `
    <div class="card-header">
      <span class="status-indicator ${statusClass}"></span>
      ${name}
    </div>
    <div class="card-body">
      <p><strong>Status:</strong> ${statusText}</p>
      <p><strong>Port:</strong> ${port}</p>
      ${isActive ? `<p><a href="${url}" class="btn btn-primary" target="_blank">Open ${name}</a></p>` : 
        `<p><a href="#" class="btn btn-primary" disabled style="opacity:0.5;cursor:not-allowed;">Service Disabled</a></p>`}
    </div>
  `;
  
  return card;
}

// Get appropriate service URL
function getServiceUrl(id, service) {
  switch (id) {
    case 'minio':
      return `http://${window.location.hostname}:${service.consolePort}`;
    case 'router':
      return `http://${window.location.hostname}:${service.port}/api/health`;
    default:
      return `http://${window.location.hostname}:${service.port}${service.url || '/'}`;
  }
}

// Show error message
function showError(message) {
  const errorElement = document.getElementById('error-message');
  errorElement.textContent = `Error: ${message}`;
  errorElement.style.display = 'block';
  
  // Hide after 5 seconds
  setTimeout(() => {
    errorElement.style.display = 'none';
  }, 5000);
}

// Initialize dashboard on load
document.addEventListener('DOMContentLoaded', function() {
  // Set up API key form
  const apiKeyForm = document.getElementById('api-key-form');
  if (apiKeyForm) {
    apiKeyForm.addEventListener('submit', function(e) {
      e.preventDefault();
      submitApiKey();
    });
  }
  
  // Set up logout button
  const logoutButton = document.getElementById('logout-button');
  if (logoutButton) {
    logoutButton.addEventListener('click', function(e) {
      e.preventDefault();
      clearApiKey();
    });
  }
  
  // Initial check for API key
  updateAuthVisibility();
  
  // Set up auto-refresh
  setInterval(function() {
    if (API_KEY) {
      fetchNodeInfo();
    }
  }, 30000); // Refresh every 30 seconds
});
