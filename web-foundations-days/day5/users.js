const API_URL = "https://jsonplaceholder.typicode.com/users"

const loadButton = document.getElementById("load-users");
const filterInput = document.getElementById("filter-input");
const status = document.getElementById("status");
const usersList = document.getElementById("users-list");

let users = [];

async function loadUsers() {
    loadButton.disabled = true;
    status.textContent = "Loading users...";

    try {
        const response = await fetch(API_URL);

        if (!response.ok) {
            throw new Error("Failed to load users.");
        }

        users = await response.json();

        status.textContent = "Users loaded successfully.";

        renderUsers(users);
    } catch (error) {
        status.textContent = "Error loading users.";
        usersList.innerHTML = "";
    } finally {
        loadButton.disabled = false;
    }
}

function renderUsers(list) { 
    usersList.innerHTML = ""; 
    if (list.length === 0) { 
        status.textContent = "No users match your filter."; 
        return; 
    } 
    
    list.forEach(function (user) { 
        const listItem = document.createElement("li"); 
        const name = document.createElement("h3"); 
        name.textContent = user.name; 
        
        const email = document.createElement("p"); 
        email.textContent = `Email: ${user.email}`; 
        
        const city = document.createElement("p"); 
        city.textContent = `City: ${user.address.city}`; 
        
        const company = document.createElement("p"); 
        company.textContent = `Company: ${user.company.name}`; 
        
        listItem.appendChild(name); 
        listItem.appendChild(email); 
        listItem.appendChild(city); 
        listItem.appendChild(company); 
        usersList.appendChild(listItem); 
    }); 
}

filterInput.addEventListener("input", function () { 
    const filterText = filterInput.value.toLowerCase(); 
    const filteredUsers = users.filter(function (user) { 
        return user.name.toLowerCase().includes(filterText); 
    }); 
    renderUsers(filteredUsers); 
});

loadButton.addEventListener("click", loadUsers);
