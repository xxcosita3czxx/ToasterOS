import { useState } from 'react'

function Face() {
  const isXScreenSaverWindow = typeof process !== 'undefined' && process.env.XSCREENSAVER_WINDOW !== undefined;

  return (
    <div className='App'>
        <p>Face</p>
    </div>
  )
}

export default Face