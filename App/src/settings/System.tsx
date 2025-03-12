import { useState } from 'react'

function System() {
  const isXScreenSaverWindow = typeof process !== 'undefined' && process.env.XSCREENSAVER_WINDOW !== undefined;

  return (
    <div className='App'>
        <p>System</p>
    </div>
  )
}

export default System