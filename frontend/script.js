fetch("https://visitor_count_api_url/count")
  .then(response => response.json())
  .then(data => {
    document.getElementById("counter").innerText = data;
  });
