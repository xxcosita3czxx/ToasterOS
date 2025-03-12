import { useState } from 'react'
import './App.css'
import Screensaver from './Screensaver';
import Menu from './Menu';

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
