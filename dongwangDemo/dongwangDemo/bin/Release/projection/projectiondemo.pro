;+
; :description:
;    base resize事件
;-
PRO Projectiondemo_resize, ev
  COMPILE_OPT idl2
  
  baseSize = [ev.x>443,ev.y>630]
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  wDraw = WIDGET_INFO(ev.top, find_by_uname='wDraw')
  
  drawXSize = baseSize[0]-442
  drawYSize = baseSize[1]-29-26
  (*pState).oView->Setproperty, dimensions=[drawXSize,drawYSize]
  sMap = (*pState).oMapProjection->_Getmapstructure()
  
  (*pState).oView->Initview,sMap
  WIDGET_CONTROL, wDraw, xsize=drawXSize, ysize=drawYSize
  (*pState).oWindow->Draw, (*pState).oView
END
;+
; :description:
;    平移事件
;-
PRO Projectiondemo_pan, ev
  COMPILE_OPT idl2
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  
  (*pState).oView->Getproperty, viewplane_rect=vp, dimensions=vd
  
  CASE ev.type OF
    0: BEGIN
      ;左键
      IF ev.press EQ 1 THEN BEGIN
        ;为平移准备
        (*pState).mouseStatus = 'PAN'
        (*pState).panStatus = [1,ev.x,ev.y]
      ENDIF
    END
    1: BEGIN
      IF (*pState).mouseStatus EQ 'PAN' THEN BEGIN
        IF ev.release EQ 1 THEN BEGIN
          (*pState).panStatus = 0
          ;更新显示
          (*pState).oWindow->Draw, (*pState).oView
        ENDIF
      ENDIF
    END
    2: BEGIN
      IF (*pState).mouseStatus EQ 'PAN' THEN BEGIN
        IF (*pState).panStatus[0] EQ 1 THEN BEGIN
          ;移动视图
          distance = [ev.x,ev.y]- (*pState).panStatus[1:2]
          geoDis = [distance[0]*vp[2]/vd[0],distance[1]*vp[3]/vd[1]]
          
          vp[0:1] = vp[0:1] - geoDis
          (*pState).panStatus[1:2] = [ev.x, ev.y]
          ;
          (*pState).oView->Setproperty, viewplane_rect=vp
          ;更新显示
          (*pState).oWindow->Draw, (*pState).oView
        ENDIF
      ENDIF
    END
    ELSE:
  ENDCASE
END

;+
; :description:
;    滚轮事件
;-
PRO Projectiondemo_wheel, ev
  COMPILE_OPT idl2
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  
  (*pState).oView->Getproperty, viewplane_rect=vp, dimensions=vd
  
  ;缩放系数
  tmpScale = 1.+ FLOAT(ev.clicks)/10
  
  ;当前鼠标位置在view中的位置
  oriLoc = [vp[0]+DOUBLE(ev.x)*vp[2]/vd[0], $
    vp[1]+DOUBLE(ev.y)*vp[3]/vd[1]]
    
  ;缩放后view显示区域
  vp[2:3] = vp[2:3]*tmpScale
  distance = (oriLoc - vp[0:1])*tmpScale
  vp[0:1] = oriLoc - distance
  
  ;设置
  (*pState).oView->Setproperty, viewplane_rect=vp
  
  ;刷新显示
  (*pState).oWindow->Draw, (*pState).oView
END

;+
; :description:
;    事件处理
;-
PRO Projectiondemo_event, ev
  COMPILE_OPT idl2
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  
  tagName = TAG_NAMES(ev, /Structure_Name)
  IF tagName EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
    ret = DIALOG_MESSAGE('关闭本软件？',/Question)
    IF ret EQ 'No' THEN RETURN
    (*pState).ret = 0
    WIDGET_CONTROL, ev.top, /Destroy
    RETURN
  ENDIF
  
  IF tagName EQ 'WIDGET_PROPSHEET_CHANGE' THEN BEGIN
    IF (ev.proptype NE 0) THEN BEGIN
      value = WIDGET_INFO(ev.id, Property_Value = ev.identifier)
      ev.component->Setpropertybyidentifier, ev.identifier, value
      WIDGET_CONTROL, (*pState).pSheet, /Refresh_Property
      prevImage = (*pState).oMapProjection->Getpreview()
      WSET, (*pState).wPrevID
      TV, prevImage
    ENDIF
  ENDIF
  
  uname = WIDGET_INFO(ev.id,/uname)
  
  CASE uname OF
    'wBase': BEGIN
      Projectiondemo_resize, ev
    END
    
    'wDraw': BEGIN
      IF ev.type EQ 4 THEN (*pState).oWindow->Draw, (*pState).oView
      
      (*pState).oView->Getproperty, initFlag=initFlag
      IF ~initFlag THEN RETURN
      
      IF ev.clicks EQ 2 THEN BEGIN
        (*pState).oView->Setproperty, /ResetDelta
        (*pState).oWindow->Draw, (*pState).oView
      ENDIF
      IF ev.type EQ 7 THEN Projectiondemo_wheel, ev
      Projectiondemo_pan, ev
    ;          PROJECTIONDEMO_CHANGE, ev
    END
    
    'wApply': BEGIN
      ;获得投影参数      
      sMap = (*pState).oMapProjection->_Getmapstructure()
  
      ;初始化系统
      (*pState).oView->Initview,sMap          
      (*pState).oWindow->Draw, (*pState).oView
    END    
    
    'wCancel': BEGIN
      (*pState).ret = 0      
      WIDGET_CONTROL, ev.top, /destroy
    END
    ELSE:
  ENDCASE
END
;;
PRO Projectiondemo_cleanup, tlb
  COMPILE_OPT idl2
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  HEAP_FREE, pState  
END
;+
; -----------------------------------------------------------------------------
PRO Projectiondemo
  COMPILE_OPT idl2
    
  CD, current = rootDir  
  oMonInfo = OBJ_NEW('IDLsysMonitorInfo')
  rects = oMonInfo -> GetRectangles(/Exclude_Taskbar)
  pmi = oMonInfo -> GetPrimaryMonitorIndex()
  OBJ_DESTROY, oMonInfo
  
  sz = rects[[2, 3], pmi]

  tlb = WIDGET_BASE( $
    title = '投影转换Demo', $
    uname = 'wBase', $
    /column, $
    /tlb_kill_request_events, $
    /base_align_left, $
    /tlb_size_events, $
    /tab_mode)
    
  wMain = WIDGET_BASE(tlb, /row)
  wLeft = WIDGET_BASE(wMain, /column)
  wRight = WIDGET_BASE(wMain, /column, /frame)
  
  ;左侧面板
  wInputFileSelBase = WIDGET_BASE(wLeft, /row)
  wInputField = Cw_field( $
    wInputFileSelBase, $
    title='显示图像文件', $
    /string, $
    /NoEdit, $
    xsize=36, $
    value='', $
    uname='wInputField')

  wProjSelBase = WIDGET_BASE(wLeft, /row)
  ;投影参数设置对象，初始显示为当前投影(projection=),WGS84坐标系
  oMapProjection = OBJ_NEW('ProjectionParameter', $
    Name='设定投影参数' , $
    projection=3        , $
    datum='WGS84'       )

  pSheet = WIDGET_PROPERTYSHEET( $
    wProjSelBase, $
    Value = oMapProjection, $
    /Sunken_Frame, $
    Scr_XSize = 310, $
    YSize = 15, $
    UName = 'pSheet', $
    /Multiple_Properties)
    
  wLeftDownBase = WIDGET_BASE(wLeft, $
    /Base_Align_Center,$
    /Align_Center, /frame,/row)
    
  wPreview = WIDGET_DRAW( $
    wLeftDownBase, $
    xsize=200, $
    ysize=200, $
    retain=2)
    
  ;右侧面板
  wDraw = WIDGET_DRAW( $
    wRight, $
    uname='wDraw', $
    xsize=sz[0]-360, $
    ysize=sz[1]-100, $
    graphics_level=2, $
    retain=0, $
    keyboard_events=2, $
    /expose_events, $
    /button_events, $
    /wheel_events, $
    /motion_events)
    
  ;ok,cancel面板
  wControl = WIDGET_BASE(wLeft, $
    /Base_Align_Center, $
    /Align_Center,/row)
    
  wCancel = WIDGET_BUTTON( $
    wControl  , $
    value = '取消', $
    uname = 'wCancel', $
    xsize = 55)
  wApply = WIDGET_BUTTON( $
    wControl  , $
    value = '应用', $
    uname = 'wApply', $
    xsize = 55)
    
  WIDGET_CONTROL, tlb, /realize
  
  WIDGET_CONTROL, wDraw, get_value=oWindow
  ;
  image = rootDir +'\day.jpg'
  WIDGET_CONTROL,wInputField, set_value = image
;  d = DIALOG_MESSAGE('oView')
  oView = OBJ_NEW('ProjectionView', $
    tlb = tlb, $
    color=[255,255,255], $
    dimensions=[sz[0]-320,sz[1]-100], $
    eye = 11, $
    zclip = [10,1], $
    image = image, $
    shpFile = [rootDir+'\shapefile\china.shp', $
    rootDir+'\shapefile\continents.shp'])
  oWindow->Draw, oView
  oWindow->Setcurrentcursor,'ARROW'

  WIDGET_CONTROL, wPreview, get_value=wPrevID
  prevImage = oMapProjection->Getpreview()
  WSET, wPrevID
  TV, prevImage
  
  pState = PTR_NEW({ $
    oWindow:oWindow, $
    oView:oView, $
    panStatus:DBLARR(3), $
    chgStatus:DBLARR(3), $
    mouseStatus:'', $
    pSheet:pSheet, $
    wPrevID:wPrevID, $
    oMapProjection:oMapProjection, $
    fileDir:'', $
    inputFile: '', $ ;输入文件名
    outputFile:'', $ ;输出文件名
    ret:0})
  WIDGET_CONTROL, tlb, set_uvalue=pState
  Xmanager, 'PROJECTIONDEMO', tlb;, /no_block
  
  ;Add By DYQ --销毁无用对象
  OBJ_DESTROY, [(*pState).oView, $
    (*pState).oMapProjection ]
    
END
; -----------------------------------------------------------------------------