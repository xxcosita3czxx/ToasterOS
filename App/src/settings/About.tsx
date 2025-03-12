import { useState } from 'react'

function About() {
  const isXScreenSaverWindow = typeof process !== 'undefined' && process.env.XSCREENSAVER_WINDOW !== undefined;

  return (
    <div className='App'>
        <p>about</p>
    </div>
  )
}

export default About