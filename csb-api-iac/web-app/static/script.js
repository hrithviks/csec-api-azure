document.getElementById('check-status-btn').addEventListener('click', function () {
    const button = this;
    const originalText = button.textContent;
    button.textContent = 'Checking...';
    button.disabled = true;

    fetch('/api/status')
        .then(response => response.json())
        .then(data => {
            updateTable(data.services);
            document.getElementById('footer-time').textContent = 'Last checked: ' + data.last_checked;
        })
        .catch(error => {
            console.error('Error fetching status:', error);
            alert('Failed to fetch status. Please check the console for details.');
        })
        .finally(() => {
            button.textContent = originalText;
            button.disabled = false;
        });
});

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