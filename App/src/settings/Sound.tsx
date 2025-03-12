import { useState } from 'react'

function Sound() {
  const isXScreenSaverWindow = typeof process !== 'undefined' && process.env.XSCREENSAVER_WINDOW !== undefined;

  return (
    <div className='App'>
        <p>Sound</p>
    </div>
  )
}

export default Sound