import './app.css'
import KioskApp from './KioskApp.svelte'

const app = new KioskApp({
  target: document.getElementById('app'),
})

export default app
