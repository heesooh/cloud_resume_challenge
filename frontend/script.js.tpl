const counter_url = "${api_url}/count"

fetch(counter_url)
  .then(response => response.json())
  .then(data => {
    document.getElementById("counter").innerText = data;
  });
