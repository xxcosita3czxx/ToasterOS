import { useState } from 'react'
import './App.css'
import Screensaver from './Screensaver';
import Menu from './Menu';

// TODO: Add maintenance mode

function App() {
  const isXScreenSaverWindow = typeof process !== 'undefined' && process.env.XSCREENSAVER_WINDOW !== undefined;

  return (
    <div className='App'>
      {isXScreenSaverWindow ? (
        <Screensaver />
      ) : (
        <Menu />
      )}
    </div>
  )
}

export default App
