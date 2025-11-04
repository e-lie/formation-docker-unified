<script>
  let backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:8000';
  let info = null;
  let name = 'World';
  let greeting = null;
  let loading = false;
  let error = null;

  async function fetchInfo() {
    loading = true;
    error = null;
    try {
      const response = await fetch(`${backendUrl}/api/info`);
      if (!response.ok) throw new Error('Failed to fetch info');
      info = await response.json();
    } catch (e) {
      error = `Error: ${e.message}`;
      console.error(e);
    } finally {
      loading = false;
    }
  }

  async function fetchGreeting() {
    loading = true;
    error = null;
    try {
      const response = await fetch(`${backendUrl}/api/hello/${name}`);
      if (!response.ok) throw new Error('Failed to fetch greeting');
      greeting = await response.json();
    } catch (e) {
      error = `Error: ${e.message}`;
      console.error(e);
    } finally {
      loading = false;
    }
  }
</script>

<main>
  <h1>Multi-Architecture App Demo</h1>

  <div class="card">
    <h2>Built with Docker Buildx</h2>
    <p>This application demonstrates multi-architecture container builds using Docker Buildx.</p>
    <p>Frontend: Svelte | Backend: FastAPI</p>
  </div>

  <div class="card">
    <h3>Get System Info</h3>
    <button on:click={fetchInfo} disabled={loading}>
      {loading ? 'Loading...' : 'Fetch Architecture Info'}
    </button>

    {#if error}
      <div class="error">{error}</div>
    {/if}

    {#if info}
      <div class="info-box">
        <h4>Backend System Information:</h4>
        <pre>{JSON.stringify(info, null, 2)}</pre>
      </div>
    {/if}
  </div>

  <div class="card">
    <h3>Custom Greeting</h3>
    <input
      type="text"
      bind:value={name}
      placeholder="Enter your name"
    />
    <button on:click={fetchGreeting} disabled={loading}>
      {loading ? 'Loading...' : 'Get Greeting'}
    </button>

    {#if greeting}
      <div class="info-box">
        <h4>{greeting.message}</h4>
        <p>Served by: {greeting.architecture}</p>
      </div>
    {/if}
  </div>
</main>
