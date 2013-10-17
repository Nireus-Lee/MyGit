;+
; :description:
;    base resize�¼�
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
;    ƽ���¼�
;-
PRO Projectiondemo_pan, ev
  COMPILE_OPT idl2
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  
  (*pState).oView->Getproperty, viewplane_rect=vp, dimensions=vd
  
  CASE ev.type OF
    0: BEGIN
      ;���
      IF ev.press EQ 1 THEN BEGIN
        ;Ϊƽ��׼��
        (*pState).mouseStatus = 'PAN'
        (*pState).panStatus = [1,ev.x,ev.y]
      ENDIF
    END
    1: BEGIN
      IF (*pState).mouseStatus EQ 'PAN' THEN BEGIN
        IF ev.release EQ 1 THEN BEGIN
          (*pState).panStatus = 0
          ;������ʾ
          (*pState).oWindow->Draw, (*pState).oView
        ENDIF
      ENDIF
    END
    2: BEGIN
      IF (*pState).mouseStatus EQ 'PAN' THEN BEGIN
        IF (*pState).panStatus[0] EQ 1 THEN BEGIN
          ;�ƶ���ͼ
          distance = [ev.x,ev.y]- (*pState).panStatus[1:2]
          geoDis = [distance[0]*vp[2]/vd[0],distance[1]*vp[3]/vd[1]]
          
          vp[0:1] = vp[0:1] - geoDis
          (*pState).panStatus[1:2] = [ev.x, ev.y]
          ;
          (*pState).oView->Setproperty, viewplane_rect=vp
          ;������ʾ
          (*pState).oWindow->Draw, (*pState).oView
        ENDIF
      ENDIF
    END
    ELSE:
  ENDCASE
END

;+
; :description:
;    �����¼�
;-
PRO Projectiondemo_wheel, ev
  COMPILE_OPT idl2
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  
  (*pState).oView->Getproperty, viewplane_rect=vp, dimensions=vd
  
  ;����ϵ��
  tmpScale = 1.+ FLOAT(ev.clicks)/10
  
  ;��ǰ���λ����view�е�λ��
  oriLoc = [vp[0]+DOUBLE(ev.x)*vp[2]/vd[0], $
    vp[1]+DOUBLE(ev.y)*vp[3]/vd[1]]
    
  ;���ź�view��ʾ����
  vp[2:3] = vp[2:3]*tmpScale
  distance = (oriLoc - vp[0:1])*tmpScale
  vp[0:1] = oriLoc - distance
  
  ;����
  (*pState).oView->Setproperty, viewplane_rect=vp
  
  ;ˢ����ʾ
  (*pState).oWindow->Draw, (*pState).oView
END

;+
; :description:
;    �¼�����
;-
PRO Projectiondemo_event, ev
  COMPILE_OPT idl2
  
  WIDGET_CONTROL, ev.top, get_uvalue=pState
  
  tagName = TAG_NAMES(ev, /Structure_Name)
  IF tagName EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
    ret = DIALOG_MESSAGE('�رձ������',/Question)
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
      ;���ͶӰ����      
      sMap = (*pState).oMapProjection->_Getmapstructure()
  
      ;��ʼ��ϵͳ
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
    title = 'ͶӰת��Demo', $
    uname = 'wBase', $
    /column, $
    /tlb_kill_request_events, $
    /base_align_left, $
    /tlb_size_events, $
    /tab_mode)
    
  wMain = WIDGET_BASE(tlb, /row)
  wLeft = WIDGET_BASE(wMain, /column)
  wRight = WIDGET_BASE(wMain, /column, /frame)
  
  ;������
  wInputFileSelBase = WIDGET_BASE(wLeft, /row)
  wInputField = Cw_field( $
    wInputFileSelBase, $
    title='��ʾͼ���ļ�', $
    /string, $
    /NoEdit, $
    xsize=36, $
    value='', $
    uname='wInputField')

  wProjSelBase = WIDGET_BASE(wLeft, /row)
  ;ͶӰ�������ö��󣬳�ʼ��ʾΪ��ǰͶӰ(projection=),WGS84����ϵ
  oMapProjection = OBJ_NEW('ProjectionParameter', $
    Name='�趨ͶӰ����' , $
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
    
  ;�Ҳ����
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
    
  ;ok,cancel���
  wControl = WIDGET_BASE(wLeft, $
    /Base_Align_Center, $
    /Align_Center,/row)
    
  wCancel = WIDGET_BUTTON( $
    wControl  , $
    value = 'ȡ��', $
    uname = 'wCancel', $
    xsize = 55)
  wApply = WIDGET_BUTTON( $
    wControl  , $
    value = 'Ӧ��', $
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
    inputFile: '', $ ;�����ļ���
    outputFile:'', $ ;����ļ���
    ret:0})
  WIDGET_CONTROL, tlb, set_uvalue=pState
  Xmanager, 'PROJECTIONDEMO', tlb;, /no_block
  
  ;Add By DYQ --�������ö���
  OBJ_DESTROY, [(*pState).oView, $
    (*pState).oMapProjection ]
    
END
; -----------------------------------------------------------------------------