let timerInterval = null;

function checkStatus() {
    // Stop the timer when a new check is initiated
    if (timerInterval) clearInterval(timerInterval);
    const button = document.getElementById('check-status-btn');
    const originalText = button.textContent;
    button.textContent = 'Checking...';
    button.disabled = true;

    fetch('/api/status')
        .then(response => {
            if (!response.ok) {
                throw new Error(`Network response was not ok: ${response.statusText}`);
            }
            return response.json();
        })
        .then(data => {
            updateTable(data.services);
            document.getElementById('footer-time').textContent = 'Last checked: ' + data.last_checked;
            // Update the timestamp and restart the visibility check
            const footer = document.getElementById('footer-time');
            footer.setAttribute('data-timestamp', data.timestamp);
            manageButtonState();
        })
        .catch(error => {
            console.error('Error fetching status:', error);
            // Optionally, display an error message on the page
            document.getElementById('status-table-body').innerHTML = `<tr><td colspan="3" class="status-error" style="text-align: center;">Failed to fetch status. Please try again.</td></tr>`;
        })
        .finally(() => {
            button.textContent = originalText;
        });
}

function updateTable(services) {
    const tbody = document.getElementById('status-table-body');
    tbody.innerHTML = ''; // Clear existing rows

    for (const serviceName in services) {
        const [status, details] = services[serviceName];
        const row = document.createElement('tr');

        const statusClass = status === 'OK' ? 'status-ok' : 'status-error';

        row.innerHTML = `
            <td>${serviceName}</td>
            <td><span class="status ${statusClass}">${status}</span></td>
            <td>${details}</td>`;
        tbody.appendChild(row);
    }
}

function manageButtonState() {
    const button = document.getElementById('check-status-btn');
    const footer = document.getElementById('footer-time');

    // Disable the button immediately
    button.disabled = true;

    // Stop any existing timer
    if (timerInterval) clearInterval(timerInterval);

    timerInterval = setInterval(() => {
        const lastCheckedTimestamp = footer.getAttribute('data-timestamp');
        if (!lastCheckedTimestamp) {
            button.disabled = false; // Enable if there's no timestamp
            clearInterval(timerInterval);
            return;
        }

        const lastCheckedDate = new Date(lastCheckedTimestamp);
        const now = new Date();
        const secondsSinceLastCheck = (now - lastCheckedDate) / 1000;

        if (secondsSinceLastCheck > 30) {
            button.disabled = false;
            clearInterval(timerInterval); // Stop checking once the button is visible
        }
    }, 1000); // Check every second
}

// Run the check when the button is clicked
document.getElementById('check-status-btn').addEventListener('click', checkStatus);
// Manage button state on initial page load
document.addEventListener('DOMContentLoaded', manageButtonState);