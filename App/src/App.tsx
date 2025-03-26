import { useState } from 'react'
import './App.css'
import Screensaver from './Screensaver';
import Menu from './Menu';

// TODO: Add maintenance mode

declare const __IS_SCREENSAVER__: boolean;

function App() {
  const isXScreenSaverWindow = typeof __IS_SCREENSAVER__ !== 'undefined' && __IS_SCREENSAVER__; 
  console.log(isXScreenSaverWindow);
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
