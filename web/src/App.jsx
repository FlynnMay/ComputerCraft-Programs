import './App.css'

const MAP_URL = import.meta.env.VITE_MAP_URL

function App() {
  if (!MAP_URL) {
    return (
      <main className="map-page">
        <p>
          Set <code>VITE_MAP_URL</code> in <code>web/.env</code> and restart the dev server.
        </p>
      </main>
    )
  }

  return (
    <main className="map-page">
      <header className="map-header">
        <h1>Turtle Control</h1>
        <a href={MAP_URL} target="_blank" rel="noreferrer">
          Open map in new tab
        </a>
      </header>
      <iframe
        className="map-frame"
        src={MAP_URL}
        title="BlueMap"
        allowFullScreen
      />
    </main>
  )
}

export default App
