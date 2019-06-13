function main{
  dolaunch().
  targetascent().
  until apoapsis >100000{
    autostage().
    print "staging".
  }

  doshutdown().
  Print "engines off".
  // executeManeuver().//incomplete
  rcs off.
  until false {
    wait until rcs.
    print maneuverburntime(nextnode).
    rcs off.
  }
}
main().
function dostage{
  wait until stage:ready.
  stage.
}
function dolaunch{
  lock throttle to 1.
  dostage().
  dostage().
}
function executeManeuver{
  parameter utime, raidal, normal, prograde.
  local mnv is node(utime, raidal, normal, prograde).
  addmaneuvertoflightplan(mnv).
  local starttime is calculatestarttime(mnv).
  wait until time:seconds > starttime -10.
  locksteeringatmanuevertarget(mnv).
  wait until time:seconds>starttime.
  lock throttle to 1.
  wait until ismaneuvercomplete(mnv).
  lock throttle to 0.
  removemanueverfromflightplan(mnv).

}
function addmaneuvertoflightplan{
  parameter mnv.
  add mnv.
}
function calculatestarttime{
  parameter mnv.
  return time:seconds +mnv:eta - maneuverburntime(mnv)/2.
}
function maneuverburntime{
  parameter mnv.
  local g0 is 9.80665.
  local m0 is ship:mass.
  local dV is mnv:deltaV:mag.
  local isp is 0.
  list engines in myEngines. //create list of all engines on ship
  for en in myEngines {
    if en:ignition and not en:flameout{ //check if engines are in current stage and active
      set isp to isp+(en:isp * (en:availablethrust / ship:availablethrust)).
    }
  }
  //rocket equations
  // dV = v(e) * ln(m0/mf)
  // mf = m0 - (fuelflow *t)
  //v(e)=isp*g0
  //F = isp * g0 * fuelflow
  //final equations after rearranging
  //fuelflow=F/(isp*g0)
  //t = (m0-mf)/fuelflow
  //mf=m0/ exp(dV/(isp*g0))
  local mf is ship:mass / constant():e^(dV/( isp *g0)).
  local fuelflow is ship:availablethrust/(isp * g0) .
  local t is (m0 - mf)/fuelflow .
  return t.
}
function locksteeringatmanuevertarget{
  parameter mnv.
  lock steering to mnv:burnvector.
}
function ismaneuvercomplete{
  parameter mnv.
  return true.
  //TO DO
}
function removemanueverfromflightplan{
  parameter mnv.
  remove mnv.
}
//until ship:maxthrust >0 {stage.}
function targetascent{
  lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
  set targetDirection to 90.
  lock steering to heading(targetDirection, targetPitch).
}

function autostage{
  if not(defined oldThrust) {
    declare global oldThrust to ship:availableThrust.
  }
  if ship:availableThrust <(oldThrust -10){
    dostage().
    wait 1.
    declare global oldThrust to ship:availableThrust.
  }
}

function doshutdown{
  lock throttle to 0.
  lock steering to prograde.
  wait until false.
}
