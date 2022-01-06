----------------------------------------------------------------------------------------------------
------------------------  Nspaint GUI engine by Loic Pujet (Chockosta) -----------------------------
----------------------------------------------------------------------------------------------------

--[[
window : {wtype,name,buttons,layout,size}
   --> wtype : "dialogBox","custom"
   --> size : {sizeX,sizeY} (only for custom)

buttons : {{"name",function1},{"name",function2},...}

layout : {{"type",...}}
   --> type : "label","textBox","colorSlider","list"

label : {text,x,y,color}
   --> if color is given, a color label is displayed

textBox : {text,x,y,sizeX,cursor,func}

colorSlider : {color,value,x,y,func}
   --> color : "red","green","blue"

list : {elements,scroll,x,y,sizeX,sizeY,selected,func}  ]]


--GUI DATA
gui={}
gui.windows={}
gui.dialogBox={}
gui.custom={}
gui.textBox={}
gui.colorSlider={}
gui.list={}
gui.resized=false
gui.img={}
gui.img.upButton=image.new("\011\000\000\000\010\000\000\000\000\000\000\000\022\000\000\000\016\000\001\0001\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\198\255\255\255\255\255\255\255\255\156\243\255\255\255\255\255\255\255\2551\1981\198\255\255\255\255\255\255\214\218\000\128\214\218\255\255\255\255\255\2551\1981\198\255\255\255\255\247\222B\136\000\128B\136\247\222\255\255\255\2551\1981\198\255\255\247\222B\136!\132\000\128!\132B\136\247\222\255\2551\1981\198\247\222B\136!\132B\136R\202B\136!\132B\136\247\2221\1981\198\132\144B\136B\136\247\222\255\255\247\222B\136B\136\132\1441\1981\198\156\243\132\144\247\222\255\255\255\255\255\255\247\222\132\144\189\2471\1981\198\255\255\222\251\255\255\255\255\255\255\255\255\255\255\222\251\255\2551\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\198")
gui.img.downButton=image.new("\011\000\000\000\010\000\000\000\000\000\000\000\022\000\000\000\016\000\001\0001\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\198\255\255\222\251\255\255\255\255\255\255\255\255\255\255\222\251\255\2551\1981\198\156\243\132\144\247\222\255\255\255\255\255\255\247\222\132\144\189\2471\1981\198\132\144B\136B\136\247\222\255\255\247\222B\136B\136\132\1441\1981\198\247\222B\136!\132B\136R\202B\136!\132B\136\247\2221\1981\198\255\255\247\222B\136!\132\000\128!\132B\136\247\222\255\2551\1981\198\255\255\255\255\247\222B\136\000\128B\136\247\222\255\255\255\2551\1981\198\255\255\255\255\255\255\214\218\000\128\214\218\255\255\255\255\255\2551\1981\198\255\255\255\255\255\255\255\255\156\243\255\255\255\255\255\255\255\2551\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\1981\198")



--------------------------------------------------------------------------------------------------------------
--------------------------------------------- USER FUNCTIONS -------------------------------------------------
--------------------------------------------------------------------------------------------------------------

function gui.errorMessage(errorText) 
 gui.addWindow("dialogBox","Error",{{"OK",function() gui.closeWindow() end}},errorText) 
end 

function gui.addTextWindow(title,text)
 gui.addWindow("dialogBox",title,{},text)
end

function gui.addCustomWindow(title,width,height)
 gui.addWindow("custom",title,{},{},{width,height})
end

function gui.addButton(text,buttonFunction)
 table.insert(gui.current().buttons,{text,buttonFunction})
end

function gui.addTextBox(xPos,yPos,width,initialText,textBoxFunction)
 if gui.current().wtype=="custom" then
  table.insert(gui.current().layout,{"textBox",text=initialText,x=xPos,y=yPos,sizeX=width,cursor=0,func=textBoxFunction})
 end
end

function gui.addLabel(xPos,yPos,labelText,labelColor)
 if gui.current().wtype=="custom" then
  table.insert(gui.current().layout,{"label",text=labelText,x=xPos,y=yPos,color=labelColor})
 end
end

function gui.addSlider(xPos,yPos,sliderColor,initialValue,sliderFunction)
 if gui.current().wtype=="custom" then
  table.insert(gui.current().layout,{"colorSlider",value=initialValue,x=xPos,y=yPos,color=sliderColor,func=sliderFunction})
 end
end

function gui.addList(xPos,yPos,width,height,listElements,listFunction)
 if gui.current().wtype=="custom" then
  table.insert(gui.current().layout,{"list",x=xPos,y=yPos,sizeX=width,sizeY=height,scroll=0,selected=1,elements=listElements,func=listFunction})
 end
end

function gui.closeWindow() 
 table.remove(gui.windows)
 gui.defaultFocus()
 platform.window:invalidate()
end 

function gui.nbWindows() 
 return #gui.windows 
end 

function gui.defaultFocus()
 if gui.nbWindows()>0 then
  gui.focus=-#gui.current().buttons
  gui.moveFocus(1)
  gui.focus=gui.focus>0 and gui.focus or -1
 end
end


--------------------------------------------------------------------------------------------------------------
--------------------------------------------END OF USER FUNCTIONS---------------------------------------------
--------------------------------------------------------------------------------------------------------------



--GUI UTILS

function gui.refreshCurrent()
 local current=gui.current()
 if current.size then
  local sizeX,sizeY=unpack(current.size)
  local xPos,yPos=(width()-sizeX)/2,(height()-sizeY-15)/2 
  platform.window:invalidate(xPos,yPos,sizeX,sizeY+39)
 else
  platform.window:invalidate()
 end
end

function gui.addWindow(windowType,windowName,windowButtons,windowLayout,windowSize) 
 table.insert(gui.windows,{wtype=windowType,name=windowName,buttons=windowButtons,layout=windowLayout,size=windowSize})
 gui.focus=-1
 platform.window:invalidate()
end

function gui.current() 
 return gui.windows[#gui.windows] 
end 



--GUI EVENTS
function gui.mouseDown(xPos,yPos)
 if gui.nbWindows()>=1 then
  local window=gui.current()
  if window.size then
   local sizeX,sizeY=unpack(window.size)
   local x,y=(width()-sizeX)/2,(height()-sizeY-15)/2
   if xPos>x and xPos<x+sizeX and yPos>y then
    gui.saveTextBox()
    if yPos<y+sizeY and gui.current().wtype=="custom" then
     gui.setFocus(xPos-x,yPos-y,window)
    elseif yPos>y+sizeY and yPos<y+sizeY+39 then
     gui.buttonDown(xPos,yPos,window.buttons)
    end
   end
  end
 end
end

function gui.paint(gc) 
 for i,e in pairs(gui.windows) do 
  gui[e.wtype].paint(gc,e,i) 
 end 
 gui.resized=false
end 

function gui.resize()
 gui.resized=true
end

function gui.tabKey()
 if gui.nbWindows()>0 then
  gui.saveTextBox()
  gui.moveFocus(1)
  gui.refreshCurrent()
 end
end

function gui.backtabKey()
 if gui.nbWindows()>0 then
  gui.saveTextBox()
  gui.moveFocus(-1)
  gui.refreshCurrent()
 end
end

function gui.arrowKey(arrow)
 if gui.nbWindows()>0 then
  if gui.focus<0 then
   if arrow=="left" then
    gui.moveFocus(-1)
    gui.refreshCurrent()
   elseif arrow=="right" then
    gui.moveFocus(1)
    gui.refreshCurrent()
   end
  elseif gui.focus>0 then
   local currentElem=gui.current().layout[gui.focus]
   if gui[currentElem[1]].arrowKey then
    gui[currentElem[1]].arrowKey(arrow,currentElem)
    gui.refreshCurrent()
   end
  end
 end
end

function gui.enterKey()
 if gui.nbWindows()>0 then
  if gui.focus<0 then
   gui.current().buttons[-gui.focus][2]()
  elseif gui.current().wtype=="custom" then
   gui.OKButton()
  end
 end
end

function gui.charIn(char)
 if gui.nbWindows()>0 then
  if gui.focus>0 then
   local currentElem=gui.current().layout[gui.focus]
   if gui[currentElem[1]].charIn then
    gui[currentElem[1]].charIn(char,currentElem)
    gui.refreshCurrent()
   end
  end
 end
end

function gui.backspaceKey()
 if gui.nbWindows()>0 then
  if gui.focus>0 then
   local currentElem=gui.current().layout[gui.focus]
   if gui[currentElem[1]].backspaceKey then
    gui[currentElem[1]].backspaceKey(currentElem)
    gui.refreshCurrent()
   end
  end
 end
end

function gui.escapeKey()
 if gui.nbWindows()>0 then
  gui.closeWindow()
 end
end



--GUI LAYOUT ELEMENTS EVENTS

function gui.textBox.charIn(char,textBox)
 if string.len(char)==1 then
  textBox.prev={textBox.text,textBox.cursor}
  textBox.text=string.usub(textBox.text,1,textBox.cursor)..char..string.usub(textBox.text,textBox.cursor+1)
  textBox.cursor=textBox.cursor+1
 end
end

function gui.textBox.arrowKey(arrow,textBox)
 if arrow=="right" and textBox.cursor<string.len(textBox.text) then
  textBox.cursor=textBox.cursor+1
 elseif arrow=="left" and textBox.cursor>0 then
  textBox.cursor=textBox.cursor-1
 end
end

function gui.textBox.mouseDown(textBox,x)
 textBox.setCursor=x-2
end

function gui.textBox.backspaceKey(textBox)
 if string.len(textBox.text)>0 and textBox.cursor>0 then
  textBox.text=string.usub(textBox.text,1,textBox.cursor-1)..string.usub(textBox.text,textBox.cursor+1)
  textBox.cursor=textBox.cursor-1
 end
end

function gui.colorSlider.arrowKey(arrow,slider)
 if arrow=="right" then
  slider.value=slider.value<250 and slider.value+5 or 255
  gui.executeFunction(slider,slider.value)
 elseif arrow=="left" then
  slider.value=slider.value>5 and slider.value-5 or 0
  gui.executeFunction(slider,slider.value)
 end
end

function gui.colorSlider.mouseDown(slider,x)
 x=(x-2)*4
 x=x>0 and x or 0
 x=x<255 and x or 255
 slider.value=x
 gui.executeFunction(slider,slider.value)
end

function gui.list.arrowKey(arrow,list)
 if arrow=="up" and list.selected>1 then
  list.selected=list.selected-1
  gui.executeFunction(list,list.elements[list.selected])
 elseif arrow=="down" and list.selected<#list.elements then
  list.selected=list.selected+1
  gui.executeFunction(list,list.elements[list.selected])
 end
end

function gui.list.mouseDown(list,x,y)
 if #list.elements>0 then
  if x>list.sizeX-17 then
   if y>list.sizeY/2 and list.selected<#list.elements then
    list.selected=list.selected+1
    gui.executeFunction(list,list.elements[list.selected])
   elseif y<list.sizeY/2 and list.selected>1 then
    list.selected=list.selected-1
    gui.executeFunction(list,list.elements[list.selected])
   end
  elseif list.fontHeight  then
   list.selected=math.floor(y/list.fontHeight)+1+list.scroll
   list.selected=list.selected<#list.elements and list.selected or #list.elements
   gui.executeFunction(list,list.elements[list.selected])
  end
 end
end


--GUI MISC FUNCTIONS

function gui.executeFunction(element,arg)
 if element.func then
  element.func(arg)
 end
end

function gui.saveTextBox()
 local elem=gui.current().layout[gui.focus]
 if elem then
  if elem[1]=="textBox" then
   gui.executeFunction(elem,elem.text)
  end
 end
end

function gui.moveFocus(nb)
 local currentWindow=gui.current()
 local test=false
 local originalFocus=gui.focus
 nb=gui.focus<0 and -nb or nb
 gui.focus=gui.focus+nb
 if #currentWindow.buttons==0 then
  gui.focus=-1
  test=true
 end
 while not test do
  if gui.focus<0 then
   if -gui.focus<=#currentWindow.buttons then
    test=true
   else
    gui.focus=1
    nb=1
   end
  elseif gui.focus==0 then
   if originalFocus<0 then
    if currentWindow.wtype=="dialogBox" then
     gui.focus=-#currentWindow.buttons
     test=true
    elseif #currentWindow.layout==0 then
     gui.focus=-#currentWindow.buttons
     test=true
    else
     gui.focus=#currentWindow.layout
     nb=-1
    end
   else
    gui.focus=nb<0 and -#currentWindow.buttons or 1
   end
  else
   if currentWindow.wtype=="dialogBox" then
    test=true
    gui.focus=-1
   elseif currentWindow.wtype=="custom" then
    if gui.focus<=#currentWindow.layout then
     if currentWindow.layout[gui.focus][1]=="label" then
      gui.focus=gui.focus+(nb<0 and -1 or 1)
     else
      test=true
     end
    else
     test=true
     gui.focus=-1
    end
   end
  end
 end
end

function gui.buttonDown(x,y,buttons)
 for i,e in pairs(buttons) do
  if x>e.pos and x<e.pos+e.size then
   gui.focus=-i
   e[2]()
  end
 end
end

function gui.OKButton()
 local buttons=gui.current().buttons
 for i=1,#buttons do
  if buttons[i][1]=="OK" then
   gui.saveTextBox()
   buttons[i][2]()
  end
 end
end

function gui.setFocus(x,y,window)
 for i,e in pairs(window.layout) do
  if e[1]=="list" then
   if x>e.x and y>e.y and x<e.x+e.sizeX and y<e.y+e.sizeY then
    gui.focus=i
    gui.list.mouseDown(e,x-e.x,y-e.y)
    gui.refreshCurrent()
   end
  elseif e[1]=="textBox" then
   if x>e.x and y>e.y and x<e.x+e.sizeX and y<e.y+22 then
    gui.focus=i
    gui.textBox.mouseDown(e,x-e.x,y-e.y)
    gui.refreshCurrent()
   end
  elseif e[1]=="colorSlider" then
   if x>e.x and y>e.y and x<e.x+68 and y<e.y+20 then
    gui.focus=i
    gui.colorSlider.mouseDown(e,x-e.x,y-e.y)
    gui.refreshCurrent()
   end
  end
 end
end



--GUI DRAWING

function gui.dialogBox.paint(gc,dialogBox,windowID) 
 local sizeX,sizeY
 if not dialogBox.size then 
  gc:setFont("sansserif","r",10)
  sizeX=improvedStr.width(gc,dialogBox.layout)+24 
  sizeY=improvedStr.height(gc,dialogBox.layout)+17 
  gui.windows[windowID].size={sizeX,sizeY}
 else
  sizeX,sizeY=unpack(dialogBox.size)
 end
 gui.paintWindowBG(gc,dialogBox.name,sizeX,sizeY) 
 gui.paintTextArea(gc,dialogBox.layout,sizeX,sizeY)
 gui.paintButtons(gc,dialogBox.buttons,sizeX,sizeY,windowID)
end 

function gui.custom.paint(gc,window,windowID)
 gui.paintWindowBG(gc,window.name,window.size[1],window.size[2])
 gui.paintLayout(gc,window.layout,window.size[1],window.size[2])
 gui.paintButtons(gc,window.buttons,window.size[1],window.size[2],windowID)
end





function gui.paintLayout(gc,layout,sizeX,sizeY)
 local x,y=(width()-sizeX)/2,(height()-sizeY-15)/2
 for i,e in pairs(layout) do
  if e[1]=="textBox" then
   gui.paintTextBox(gc,e,x,y,gui.focus==i)
  elseif e[1]=="label" then
   gui.paintLabel(gc,e,x,y)
  elseif e[1]=="colorSlider" then
   gui.paintColorSlider(gc,e,x,y,gui.focus==i)
  elseif e[1]=="list" then
   gui.paintList(gc,e,x,y,gui.focus==i)
  end
 end
end

function gui.paintLabel(gc,label,x,y)
 gc:setFont("sansserif","r",10)
 if label.color then
  gc:setColorRGB(0,0,0)
  gc:fillRect(x+label.x,y+label.y,30,20)
  gc:setColorRGB(unpack(label.color))
  gc:fillRect(x+label.x+1,y+label.y+1,28,18)
 else
  gc:setColorRGB(0,0,0)
  gc:drawString(label.text,x+label.x,y+label.y,"top")
 end
end

function gui.paintTextBox(gc,textBox,x,y,selected)
 if gc:getStringWidth(textBox.text)>textBox.sizeX-5 then
  textBox.prev=textBox.prev or {"",0}
  textBox.text,textBox.cursor=unpack(textBox.prev)
 end
 if textBox.setCursor then
  textBox.cursor=string.len(textBox.text)
  for i=string.len(textBox.text),1,-1 do
   if gc:getStringWidth(string.sub(textBox.text,1,i))>textBox.setCursor then
    textBox.cursor=i-1
   end
  end
  textBox.setCursor=nil
 end
 if selected then
  gc:setColorRGB(50,150,190)
  gc:fillRect(x+textBox.x-2,y+textBox.y-2,textBox.sizeX+5,27)
 end
 gc:setColorRGB(255,255,255)
 gc:fillRect(x+textBox.x,y+textBox.y,textBox.sizeX,22)
 gc:setColorRGB(0,0,0)
 gc:drawRect(x+textBox.x,y+textBox.y,textBox.sizeX-1,22)
 gc:setFont("sansserif","r",10)
 gc:drawString(textBox.text,x+textBox.x+3,y+textBox.y+1,"top")
 if selected then
  gc:fillRect(gc:getStringWidth(string.usub(textBox.text,1,textBox.cursor))+x+textBox.x+3,y+textBox.y+2,1,19)
 end
end

function gui.paintColorSlider(gc,slider,x,y,selected)
 if selected then
  gc:setColorRGB(50,150,190)
  gc:fillRect(x+slider.x-2,y+slider.y-2,72,24)
 end
 gc:setColorRGB(0,0,0)
 gc:fillRect(x+slider.x,y+slider.y,68,20)
 for i=0,63 do
  gc:setColorRGB(slider.color=="red" and i*4 or newColor[1],slider.color=="green" and i*4 or newColor[2],slider.color=="blue" and i*4 or newColor[3])
  gc:fillRect(x+slider.x+i+2,y+2+slider.y,1,16)
 end
 if platform.isColorDisplay() then
  gc:setColorRGB(255-slider.value,255-slider.value,255-slider.value)
 else
  gc:setColorRGB(255,255,255)
 end
 gc:fillRect(x+slider.x+slider.value/4+1,y+slider.y-2,3,24)
end

function gui.paintList(gc,list,x,y,selected)
 if selected then
  gc:setColorRGB(50,150,190)
  gc:fillRect(x+list.x-2,y+list.y-2,list.sizeX+4,list.sizeY+4)
 end
 gc:setColorRGB(0,0,0)
 gc:fillRect(list.x+x,list.y+y,list.sizeX,list.sizeY)
 gc:setColorRGB(255,255,255)
 gc:fillRect(list.x+1+x,list.y+1+y,list.sizeX-2,list.sizeY-2)
 gc:setColorRGB(100,100,100)
 gc:drawImage(gui.img.upButton,list.x+x+list.sizeX-14,y+list.y+3)
 gc:drawImage(gui.img.downButton,list.x+x+list.sizeX-14,y+list.y+list.sizeY-13)
 gc:drawRect(list.x+x+list.sizeX-14,y+list.y+15,10,list.sizeY-31)
 gc:setFont("sansserif","r",10)
 local fontHeight=list.fontHeight
 if not fontHeight then
  list.fontHeight=gc:getStringHeight("a")
  fontHeight=list.fontHeight
 end
 local capacity=math.floor(list.sizeY/fontHeight)
 if list.selected<list.scroll+1 then
  list.scroll=list.selected-1
 elseif list.selected>list.scroll+capacity then
  list.scroll=list.selected-capacity
 end
 if list.scroll>#list.elements-capacity then
  local scroll=#list.elements-capacity
  scroll=scroll<0 and 0 or scroll
  list.scroll=scroll
 end
 if #list.elements*fontHeight>list.sizeY then
  local scrollBarSize=(list.sizeY-31)*list.sizeY/(#list.elements*fontHeight)
  gc:fillRect(list.x+x+list.sizeX-14,y+list.y+15+list.scroll*(list.sizeY-31)/#list.elements,11,scrollBarSize)
 end
 gc:setColorRGB(0,0,0)
 local step=0
 for i=list.scroll+1,list.scroll+capacity do
  if list.elements[i] then
   if list.selected==i then
    gc:setColorRGB(unpack(selected and {50,150,190} or {200,200,200}))
    gc:fillRect(list.x+x+1,list.y+y+step*fontHeight+1,list.sizeX-16,fontHeight-2)
    gc:setColorRGB(0,0,0)
   end
   gc:drawString(list.elements[i],list.x+x+3,list.y+y+step*fontHeight,"top")
   step=step+1
  end
 end
end

function gui.paintButtons(gc,buttons,sizeX,sizeY,windowID)
 local x,y=(width()-sizeX)/2,(height()-sizeY-15)/2
 gc:setFont("sansserif","r",10)
 if (not buttons[1].size) or gui.resized then
  local totalSize,size,pos=-7,{},{}
  for i,e in pairs(buttons) do
   size[i]=gc:getStringWidth(e[1])+10
   totalSize=totalSize+size[i]+7
  end
  pos[1]=(width()-totalSize)/2
  for i=2,#buttons do
   pos[i]=pos[i-1]+size[i-1]+7
  end
  for i,e in pairs(buttons) do
   gui.windows[windowID].buttons[i].size=size[i]
   gui.windows[windowID].buttons[i].pos=pos[i]
  end
  buttons=gui.windows[windowID].buttons
 end
 for i,e in pairs(buttons) do
  gc:setColorRGB(136,136,136)
  gc:fillRect(e.pos,y+sizeY+9,e.size,23)
  gc:fillRect(e.pos+1,y+sizeY+8,e.size-2,25)
  gc:fillRect(e.pos+2,y+sizeY+7,e.size-4,27)
  gc:setColorRGB(255,255,255)
  gc:fillRect(e.pos+2,y+sizeY+9,e.size-4,23)
  gc:setColorRGB(0,0,0)
  gc:drawString(e[1],e.pos+5,y+sizeY+20,"middle")
 end
 if gui.focus<0 and windowID==gui.nbWindows() then
  local button=buttons[-gui.focus]
  if platform.isColorDisplay() then
   gc:setColorRGB(50,150,190)
  else
   gc:setColorRGB(0,0,0)
  end
  gc:drawRect(button.pos-3,y+sizeY+4,button.size+5,32)
  gc:drawRect(button.pos-2,y+sizeY+5,button.size+3,30)
 end
end

function gui.paintTextArea(gc,text,sizeX,sizeY) 
 local x,y=(width()-sizeX)/2,(height()-sizeY-15)/2
 if platform.isColorDisplay() then 
  gc:setColorRGB(128,128,128)
 else
  gc:setColorRGB(255,255,255)
 end
 gc:drawRect(x+6,y+6,sizeX-13,sizeY-13)
 gc:setColorRGB(0,0,0) 
 gc:setFont("sansserif","r",10)
 improvedStr.draw(gc,text,x+12,y+9) 
end 

function gui.paintWindowBG(gc,name,sizeX,sizeY) 
 local x,y=(width()-sizeX)/2,(height()-sizeY-15)/2 
 if platform.isColorDisplay() then
  gc:setColorRGB(100,100,100) 
 else
  gc:setColorRGB(200,200,200)
 end
 gc:fillRect(x-1,y-23,sizeX+4,sizeY+65) 
 gc:fillRect(x,y-22,sizeX+4,sizeY+65) 
 gc:fillRect(x+1,y-21,sizeX+4,sizeY+65) 
 if platform.isColorDisplay() then
  gc:setColorRGB(128,128,128) 
 else
  gc:setColorRGB(0,0,0) 
 end
 gc:fillRect(x-2,y-24,sizeX+4,sizeY+65) 
 if platform.isColorDisplay() then
  for i=1,22 do 
   gc:setColorRGB(32+i*3,32+i*3,32+i*3) 
   gc:fillRect(x,y+i-23,sizeX,1) 
  end 
 else
  gc:setColorRGB(0,0,0)
  gc:fillRect(x,y-22,sizeX,22)
 end
 gc:setColorRGB(255,255,255) 
 gc:setFont("sansserif","r",10) 
 gc:drawString(name,x+4,y-9,"baseline") 
 gc:setColorRGB(224,224,224) 
 gc:fillRect(x,y,sizeX,sizeY+39) 
 gc:setColorRGB(128,128,128) 
 gc:fillRect(x+6,y+sizeY,sizeX-12,2) 
end 


function width() 
 return platform.window:width() 
end

function height() 
 return platform.window:height() 
end
