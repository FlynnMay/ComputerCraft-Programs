const MAP_URL = import.meta.env.VITE_MAP_URL

export default function MapView() {
  if (!MAP_URL) {
    return (
      <p>
        Set <code>VITE_MAP_URL</code> in <code>web/.env</code> and restart the dev server.
      </p>
    )
  }

  return (
    <>
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
    </>
  )
}
