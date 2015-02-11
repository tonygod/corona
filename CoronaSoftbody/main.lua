--[[ 
This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the use 
of this software.

Permission is granted to anyone to use this software for any purpose, including 
commercial applications, and to alter it and redistribute it freely, subject to 
the following restrictions:

1. The origin of this software must not be misrepresented; you must not claim 
that you wrote the original software. If you use this software in a product, an 
acknowledgment in the product documentation would be appreciated but is not 
required.

2. Altered source versions must be plainly marked as such, and must not be 
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution. 
]]--

-- GLOBAL HELPERS
_G.FORCE = 12
_G.DEBUG = 0 -- 1 shows centerNode and outerNodes, 2 sets drawMode to "hybrid"
_G.FRICTION = 0 -- does nothing right now

_G.CW = display.contentWidth
_G.CH = display.contentHeight
_G.CX = display.contentCenterX
_G.CY = display.contentCenterY
_G.AW = display.actualContentWidth
_G.AH = display.actualContentHeight
    
-- all of the displayObjects created in this demo will go in this group
local ballGroup = display.newGroup()

--==============================================================================
--BEGIN port of indieretro code
--==============================================================================
--indieretro.co.uk
--by steven/shorefire/indieretro
--ported to Corona SDK by tonygod (@sharkappsllc)

-- basic testbed
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 9.81 ) -- TG do not know why above is *64
local softBody = nil -- TG this will be the visible polygon softbody

-- the position we will create the softbody at
local x = 240
--local y = 240
local y = 100 -- TG move it up a bit to allow for more props below

-- the radius of the entire softbody
local radius = 124

-- the amount of outer nodes
local nodes = radius/2

-- the frequency and damping of our physics
local damping = 0.4
local frequency = 1.5

-- lets create our center body and store it in a table
centerNode = {}
centerNode.body = display.newCircle( ballGroup, x, y, 32 )
physics.addBody( centerNode.body, "dynamic", { radius=32 } )
centerNode.fill = { 0.5, 0.5, 0.5, 1.0 }
centerNode.body.alpha = _G.DEBUG -- TG only visible when debugging

-- next lets create our outer nodes and store them in a table
outerNodes = {}

for node = 1, nodes do

    -- the angle from the center body to the outer node
    local angle = (2 * math.pi) / nodes * node

    -- get the position of the new node using the angle and radius as offset
    local nodeX = x + radius * math.cos(angle)
    local nodeY = y + radius * math.sin(angle)

    -- create our body and fix our shape to it
    local nodeBody = display.newCircle( ballGroup, nodeX, nodeY, radius/24 )
    physics.addBody( nodeBody, "dynamic", { radius=radius/24 } )
    nodeBody.alpha = _G.DEBUG -- TG only visible when debugging

    --[[
        now lets connect the node to the center body with a distanceJoint
        you may notice we use the same position for both anchor points of the joint
        
        I personally find this creates a much better outcome,
        as the outer nodes stay in rotation with the center body
    --]]
    
    local nodeJoint = physics.newJoint( "distance", nodeBody, centerNode.body, nodeX, nodeY, nodeX, nodeY )
    
    -- next lets set the damping and frequency
    nodeJoint.dampingRatio = damping
    nodeJoint.frequency = frequency

    -- and finally, lets add everything to the outerNodes table
    table.insert(outerNodes, {body = nodeBody, fixture = nodeBody, joint = nodeJoint})
    -- TG fixture property is not used
end


-- next we need to connect each outer node to the following node
for i = 1, #outerNodes do
    -- we get two nodes, the one on this iteration and the following node
    local nodeA = outerNodes[i]

    -- get the node following i
    local nodeB = outerNodes[(i % #outerNodes) + 1]
    
    -- create a distanceJoint between the two nodes, this time with no frequency or damping
    nodeA.joint2 = physics.newJoint( "distance", nodeA.body, nodeB.body, nodeA.body.x, nodeA.body.y, nodeB.body.x, nodeB.body.y )
    nodeA.joint2.frequency = 1 -- TG added
    nodeA.joint2.dampingRatio = 1 -- TG added
end 

--[[ TG
in Corona, the objects are already drawn, but we set alpha=0 on them
because we don't want to see them, rather the polygon created in updateShape()
so commenting this out
--]]
-- lets do some debug drawing, to make sure its all working
--function love.draw()    
--    -- draw the center body
--    love.graphics.circle("line", centerNode.body:getX(), centerNode.body:getY(), centerNode.shape:getRadius())
--
--    -- draw the outer nodes
--    for i,v in ipairs(outerNodes) do
--        love.graphics.circle("line", v.body:getX(), v.body:getY(), outerNodeShape:getRadius())
--    end
--end


function updateShape()
    -- a table to store the positions in
    local nodePositions = {}
    
    -- lets iterate over every 4th node, to keep it smooth
    for i = 1, #outerNodes, 4 do
        local node = outerNodes[i]

        -- add the x and y positions into the table
        table.insert(nodePositions, node.body.x)
        table.insert(nodePositions, node.body.y)
    end
    
    -- draw a filled polygon using the new table
    if ( softBody ) then
        softBody:removeSelf()
    end
    softBody = display.newPolygon( ballGroup, centerNode.body.x, centerNode.body.y, nodePositions )
    --[[ TG note from Corona SDK docs
    Draws a polygon shape by providing the outline (contour) of the shape. 
    This includes convex or concave shapes. Self-intersecting shapes, however, 
    are not supported and will result in undefined behavior.
    --]]

    -- TG playing with different fill types
--    softBody.fill = { type="image", filename="Icon-72@2x.png" }
--    softBody.fill = { type="gradient", color1={ 0.5, 0.5, 0.5, 1.0 }, color2={ 0.2, 0.2, 0.2, 1.0}, direction="down" }
    softBody.fill = { 0.5, 0.5, 0.5, 1.0 }
end

--==============================================================================
--END port of indieretro code
--==============================================================================


-- add a floor
local ground = display.newRect( ballGroup, 0, 0, _G.AW, 100 )
ground.x = _G.CX
ground.y = _G.CH
physics.addBody( ground, "static", { friction=_G.FRICTION } )
ground.fill = { 0, 0.5, 0, 1 }
-- if ground touched, launch the softbody upward
ground.touch = function( self, event )
    if ( event.phase == "ended" ) then
        centerNode.body:applyForce( 0, -_G.FORCE * 2, centerNode.body.x - 20, centerNode.body.y - 20)
    end
    return true
end
ground:addEventListener( "touch" )

-- add a ramp
local ramp1 = display.newRect( ballGroup, 0, 0, 300, 10 )
ramp1.x = x
ramp1.y = y + 200
ramp1.rotation = 15
physics.addBody( ramp1, "static", { friction=_G.friction } )

-- add wall on right
local wallRight = display.newRect( ballGroup, 0, 0, 200, 300 )
wallRight.x = _G.CW - 100
wallRight.y = _G.CH - wallRight.contentHeight / 2
physics.addBody( wallRight, "static", {} )
wallRight.fill = { 0.5, 0.5, 1, 0.5 }

-- when right wall is hit, apply x and y force to throw the soft body
wallRight.collision = function( self, event )
    if ( event.phase == "began" ) then
        centerNode.body:applyForce( -_G.FORCE, -_G.FORCE, centerNode.body.x - 20, centerNode.body.y - 20)
    end
    return true
end
wallRight:addEventListener( "collision" )

-- add wall on left
local wallLeft = display.newRect( ballGroup, 0, 0, 10, 300 )
wallLeft.x = 100
wallLeft.y = _G.CH - wallLeft.contentHeight / 2
physics.addBody( wallLeft, "static", {} )
wallLeft.fill = { 0.8, 0, 0, 1 }

-- when left wall is hit, apply x and y force to throw the soft body
wallLeft.collision = function( self, event )
    if ( event.phase == "began" ) then
        centerNode.body:applyForce( _G.FORCE, -_G.FORCE, centerNode.body.x - 20, centerNode.body.y - 20)
    end
    return true
end
wallLeft:addEventListener( "collision" )


-- if debugging, do not show polygon, show nodes
if ( _G.DEBUG == 2 ) then
    -- show physics bodies and individual nodes, hide polygon shape
    physics.setDrawMode( "hybrid" )
elseif ( _G.DEBUG == 0 ) then
    -- show polygon shape and update the shape on each frame
    Runtime:addEventListener( "enterFrame", updateShape )
end
