



FUNCTION LLTOXYZ, lat, lon, radius

  COMPILE_OPT IDL2
  xyz=FLTARR(3,N_ELEMENTS(lat), /NOZERO)
  rad = radius
  lat = ABS(lat + (-90))
  ; latitude
  xyz[0,*] = (FLOAT(rad) * COS(!DtoR * (-(lon))) * (SIN(!DtoR * lat))); + self.pos[0]
  ; longitude
  xyz[1,*] = (FLOAT(rad) * SIN(!DtoR * (-(lon))) * (SIN(!DtoR * lat))); + self.pos[1]
  ; Z value
  xyz[2,*] = (FLOAT(rad) * COS(!DtoR * lat));
  RETURN, xyz
  
END

FUNCTION XYZTOLL, x, y, z

  COMPILE_OPT IDL2
  lat = !RaDeg * ACOS(z / SQRT(x^2 + y^2 + z^2))
  lon = !RaDeg * ATAN(y, x)
  lon = lon + (-90.0)
  lat = (lat + (-90.0)) * (-1.0)
  RETURN, [lat, lon]
END


FUNCTION CREATESKY,oContainer,p1=p1,p2=p2,p3=p3,p4=p4,texture_map=texture_map
  CATCH, error_status
  IF Error_status NE 0 THEN RETURN,OBJ_NEW('IDLgrModel')
  IF N_ELEMENTS(p1) EQ 0 THEN p1=4
  IF N_ELEMENTS(p2) EQ 0 THEN p2=2*!Pi
  IF N_ELEMENTS(p3) EQ 0 THEN p3=-!Pi/10
  IF N_ELEMENTS(p4) EQ 0 THEN p4=!Pi/4
  
  n=100L
  m=100L
  array=FLTARR(n,m)
  a=0.5
  b=0.49
  c=0.5
  FOR j=0, m-1 DO BEGIN
    y=b*COS(j*!pi/m)
    FOR i=0,n-1 DO BEGIN
      z=a*SIN(j*!pi/m)*COS(i*2*!pi/n)
      x=c*SIN(j*!pi/m)*SIN(i*2*!pi/n)
      r=SQRT(x^2+y^2+z^2)
      array[i,j]=r
    ENDFOR
  ENDFOR
  MESH_OBJ, 4, Vertex_List, Polygon_List, array, p1=p1, p2=p2, p3=p3, p4=p4
  READ_JPEG, !SYSDIR+'\projection\day.jpg', idata, /True
  
  VNum=n*m
  
  tco=FLTARR(2,VNum)
  FOR i=0l,n-1 DO BEGIN
    FOR j=0l,m-1 DO BEGIN
      tco[0,j+i*n]=j*1.0/n
      tco[1,j+i*m]=i*1.0/m
    ENDFOR
  ENDFOR
  
  file = !SYSDIR+'\projection\cloud.dat'
  
  cloud = BYTARR(1000, 700)
  OPENR, 1, file
  READU, 1, cloud
  CLOSE, 1
  
  cloud = SMOOTH(cloud, 7, /edge_truncate)
  
  sizeImage = SIZE(cloud)
  rgba = BYTARR(2, sizeImage[1], sizeImage[2])
  rgba[0, *, *] = cloud
  rgba[1, *, *] = cloud
  oImage = OBJ_NEW('IDLgrImage', rgba, HIDE=1)
  oContainer->ADD, oImage
  ;
  ;IF N_Elements(texture_map) NE Obj_New() THEN oImage=texture_map
  ;
  oEarth=OBJ_NEW('IDLgrPolygon'           , $
    Vertex_list*1.1         , $
    poly = Polygon_list     , $
    color = [255,255,255]   , $
    style = 2               , $
    Shading = 0             , $
    TEXTURE_MAP = oImage    , $
    TEXTURE_COORD = tco     )
  oEarthModel=OBJ_NEW('IDLgrModel')
  oEarthModel->ADD,oEarth
  
  RETURN, oEarthModel
END

;----------------------------------------------------------------------------
;卫星创建模块
;----------------------------------------------------------------------------
FUNCTION CREATESAT, oContainer, Color = color, Type = type
  CATCH, error_status
  IF Error_status NE 0 THEN RETURN,OBJ_NEW('IDLgrModel')
  IF N_ELEMENTS(color) EQ 0 THEN BEGIN
    color = [100,100,255]
    lColor = [255,255,80]
  ENDIF ELSE lColor = color
  
  mainModel = OBJ_NEW('IDLgrModel')
  xp=[-0.07, 0.07, 0.07,-0.07, $
    -0.07, 0.07, 0.07,-0.07]
  yp=[-0.40,-0.40, 0.40, 0.40, $
    -0.40,-0.40, 0.40, 0.40]
  zp=[ 0.07, 0.07, 0.07, 0.07, $
    -0.07,-0.07,-0.07,-0.07]
  bloc1Vertices = FLTARR(3,8)
  bloc1Vertices = [ [xp], [yp], [zp] ]
  bloc1Vertices = TRANSPOSE(bloc1Vertices)
  bloc1Mesh = [ [4,0,1,2,3], $
    [4,1,5,6,2], $
    [4,4,7,6,5], $
    [4,0,3,7,4], $
    [4,3,2,6,7], $
    [4,0,4,5,1] ]
  bloc1List = FLTARR(3,24)
  bloc1NewMesh = bloc1Mesh
  j = 0
  FOR i = 0, 5 DO BEGIN
    bloc1List[0:2, i*4+0] = bloc1Vertices[0:2, bloc1Mesh[i*5+1]]
    bloc1List[0:2, i*4+1] = bloc1Vertices[0:2, bloc1Mesh[i*5+2]]
    bloc1List[0:2, i*4+2] = bloc1Vertices[0:2, bloc1Mesh[i*5+3]]
    bloc1List[0:2, i*4+3] = bloc1Vertices[0:2, bloc1Mesh[i*5+4]]
    bloc1NewMesh[*,i] = [4, j+0, j+1, j+2, j+3]
    j = j + 4
  ENDFOR
  oBloc1 = OBJ_NEW('IDLgrPolygon', bloc1List, $
    POLYGONS=bloc1NewMesh, COLOR=[255,255,0] )
  mainModel->ADD, oBloc1
  
  ;  Create bloc2 : solar array panel.
  ;
  xp=[0.20, 0.60, 0.60, 0.20, $
    0.20, 0.60, 0.60, 0.20]
  yp=[-0.20,-0.20, 0.20, 0.20, $
    -0.20,-0.20, 0.20, 0.20]
  zp=[ 0.02, 0.02, 0.02, 0.02, $
    -0.02,-0.02,-0.02,-0.02]
  bloc2Vertices = FLTARR(3,8)
  bloc2Vertices = [ [xp], [yp], [zp] ]
  bloc2Vertices = TRANSPOSE(bloc2Vertices)
  bloc2Mesh = [ [4,0,1,2,3], $
    [4,1,5,6,2], $
    [4,4,7,6,5], $
    [4,0,3,7,4], $
    [4,3,2,6,7], $
    [4,0,4,5,1] ]
  bloc2List = FLTARR(3,24)
  bloc2NewMesh = bloc1Mesh
  j = 0
  FOR i = 0, 5 DO BEGIN
    bloc2List[0:2, i*4+0] = bloc2Vertices[0:2, bloc2Mesh[i*5+1]]
    bloc2List[0:2, i*4+1] = bloc2Vertices[0:2, bloc2Mesh[i*5+2]]
    bloc2List[0:2, i*4+2] = bloc2Vertices[0:2, bloc2Mesh[i*5+3]]
    bloc2List[0:2, i*4+3] = bloc2Vertices[0:2, bloc2Mesh[i*5+4]]
    bloc2NewMesh[*,i] = [4, j+0, j+1, j+2, j+3]
    j = j + 4
  ENDFOR
  oBloc2 = OBJ_NEW('IDLgrPolygon', bloc2List, $
    POLYGONS=bloc2NewMesh, COLOR=color);COLOR=[0,255,0]);[100,100,255] )
  mainModel->ADD, oBloc2
  
  ;  Create bloc3 : the other solar array panel.
  ;
  xp=[-0.20, -0.60, -0.60, -0.20, $
    -0.20, -0.60, -0.60, -0.20]
  yp=[-0.20,-0.20, 0.20, 0.20, $
    -0.20,-0.20, 0.20, 0.20]
  zp=[ 0.02, 0.02, 0.02, 0.02, $
    -0.02,-0.02,-0.02,-0.02]
  bloc3Vertices = FLTARR(3,8)
  bloc3Vertices = [ [xp], [yp], [zp] ]
  bloc3Vertices = TRANSPOSE(bloc3Vertices)
  bloc3Mesh = [ [4,0,1,2,3], $
    [4,1,5,6,2], $
    [4,4,7,6,5], $
    [4,0,3,7,4], $
    [4,3,2,6,7], $
    [4,0,4,5,1] ]
  bloc3List = FLTARR(3,24)
  bloc3NewMesh = bloc3Mesh
  j = 0
  FOR i = 0, 5 DO BEGIN
    bloc3List[0:2, i*4+0] = bloc3Vertices[0:2, bloc3Mesh[i*5+1]]
    bloc3List[0:2, i*4+1] = bloc3Vertices[0:2, bloc3Mesh[i*5+2]]
    bloc3List[0:2, i*4+2] = bloc3Vertices[0:2, bloc3Mesh[i*5+3]]
    bloc3List[0:2, i*4+3] = bloc3Vertices[0:2, bloc3Mesh[i*5+4]]
    bloc3NewMesh[*,i] = [4, j+0, j+1, j+2, j+3]
    j = j + 4
  ENDFOR
  oBloc3 = OBJ_NEW('IDLgrPolygon', bloc3List, $
    POLYGONS=bloc3NewMesh, COLOR=color) ;[100,100,255] )
  mainModel->ADD, oBloc3
  ;
  x = [0.07, 0.20]
  y = [0.00, 0.18]
  z = [0.0, 0.0]
  oLine1 = OBJ_NEW('IDLgrPolyline', x, y, z, $
    COLOR=[255, 255, 255])
  mainModel->ADD, oLine1
  x = [0.07, 0.20]
  y = [-0.00, -0.18]
  z = [0.0, 0.0]
  oLine2 = OBJ_NEW('IDLgrPolyline', x, y, z, $
    COLOR=[255, 255, 255])
  mainModel->ADD, oLine2
  x = [-0.07, -0.20]
  y = [0.00, 0.18]
  z = [0.0, 0.0]
  oLine3 = OBJ_NEW('IDLgrPolyline', x, y, z, $
    COLOR=[255, 255, 255])
  mainModel->ADD, oLine3
  x = [-0.07, -0.20]
  y = [-0.00, -0.18]
  z = [0.0, 0.0]
  oLine4 = OBJ_NEW('IDLgrPolyline', x, y, z, $
    COLOR=[255, 255, 255])
  mainModel->ADD, oLine4
  ;
  oModel=OBJ_NEW('IDLgrmodel', Name = 'lightmodel')
  oLight1 = OBJ_NEW('IDLgrLight'          , $
    loc = [0,0,0]           , $
    DIRECTION = [0, 0, -1]  , $
    COLOR = [255,255,255]   , $
    TYPE = 3                , $
    cone = 40               , $
    INTENSITY = 1           , $
    focus = 0               )
    
  MESH_OBJ, 6, Vertex_List, Polygon_List, $
    [[3.25, 0.0, -10.75], [0, 0.0, 0.0]], $
    P1=200, P2=[0.0, 0.0, 0.0]
  sizeImage = SIZE(vertex_list)
  rgba = BYTARR(4, sizeImage[2], sizeImage[3])
  IF (N_ELEMENTS(color) NE 0) THEN BEGIN
    rgba[0, *, *] = lcolor[0]
    rgba[1, *, *] = lcolor[1]
    rgba[2, *, *] = lcolor[2]
    rgba[3, *, *] = 50
  ENDIF ELSE BEGIN
    rgba[0, *, *] = 0
    rgba[1, *, *] = 255
    rgba[2, *, *] = 0
    rgba[3, *, *] = 10
  ENDELSE
  
  READ_JPEG, !SYSDIR+'\projection\aa.jpg', image, True=1
  image = BYTSCL(DIST(32))
  pattern=CVTTOBM(image)
  pattern=BYTE(RANDOMN(seed,32,4)*255)
  
  oImage= OBJ_NEW('IDLgrImage', rgba, HIDE=0)
  oContainer->ADD, oImage
  
  tmp_polygon=OBJ_NEW('IDLgrPolygon'          , $
    Vertex_List             , $
    Poly = Polygon_List     , $
    Texture_map = oImage    , $
    Shading = 0             , $
    Color = [255,255,255]   , $
    Name = 'light'			)
    
  omodel->ADD,tmp_polygon
  omodel->ADD,oLight1
  mainModel->ADD,omodel
  mainModel->SCALE, 0.05, 0.05, 0.05
  ;
  ;    xObjview,mainModel
  
  RETURN,mainModel
  
END


FUNCTION CREATEORBIT, oContainer, sState, Data=data, R = r, Color = color
  CATCH, error_status
  IF Error_status NE 0 THEN RETURN,OBJ_NEW('IDLgrModel')
  
  Num=300
  x=FLTARR(Num+1)
  y=FLTARR(Num+1)
  z=FLTARR(Num+1)
  x0=0
  y0=0
  z0=0
  r=r
  pha=0
  FOR i=0,Num DO BEGIN
    pha=2*!PI*(i-65)/Num;-!Pi
    lam=116*!DTOR
    x[i]=x0+r*COS(pha)*COS(lam)
    y[i]=y0+r*COS(pha)*SIN(lam)
    z[i]=z0-r*SIN(pha)
  ENDFOR
  
  oPoly=OBJ_NEW('IDLgrPolyline',x,y,z,color=color,linestyle=2)
  oModel=OBJ_NEW('IDLgrModel')
  oModel->ADD,oPoly
  
  line = FLTARR(3,N_ELEMENTS(x))
  line[0,*] = x
  line[1,*] = y
  line[2,*] = z
  sState.CHANGESATLINE = PTR_NEW(line)
  RETURN,oModel
END
FUNCTION CREATEEARTH,oContainer,p1=p1,p2=p2,p3=p3,p4=p4,texture_map=texture_map
  CATCH, error_status
  IF Error_status NE 0 THEN RETURN,OBJ_NEW('IDLgrModel')
  routinefile = ROUTINE_FILEPATH('SATELLITE_DEMO')
  
  READ_JPEG, FILE_DIRNAME(routinefile)+'\projection\day.jpg',$
    idata, TRUE=1
  oImage = OBJ_NEW('IDLgrImage', idata, INTERLEAVE = 0)
  oContainer->ADD, oImage
  
  oEarth = OBJ_NEW('orb', COLOR=[255, 255, 255], RADIUS=0.5, $
    DENSITY=5, /TEX_COORDS, TEXTURE_MAP=oImage)
    
  oEarthModel = OBJ_NEW('IDLgrModel')
  oEarthModel->ADD,oEarth
  
  RETURN, oEarthModel
  
END

;三维显示事件处理模块
;-----------------------------------------------------------
PRO EARTHSIM_EVENT, ev

  COMPILE_OPT IDL2
  CATCH, error_status
  IF Error_status NE 0 THEN RETURN
  WIDGET_CONTROL, ev.TOP, Get_Uvalue = pState
  
  ; Handle KILL requests.
  
  IF TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN BEGIN
    ; Destroy the objects.
    HEAP_FREE, pState
    WIDGET_CONTROL, ev.TOP, /Destroy
    RETURN
  ENDIF
  IF OBJ_VALID((*pState).OWINDOW) EQ 0 THEN BEGIN
    WIDGET_CONTROL,ev.TOP,/destroy
    RETURN
  ENDIF
  
  uName = WIDGET_INFO(ev.ID, /UName)
  
  CASE uName OF
    'TIMER': BEGIN
      ;
      scale = 0.1
      ;获取当前时间
      time = SYSTIME()
      time = (STRSPLIT(time , ' ' , /Extract))[3]
      (*pState).TIMETEXT1->SETPROPERTY,strings = time
      
      (*pState).OSATELLITE1->RESET
      xyz = [(*(*pState).CHANGESATLINE)[0,(*pState).CHANGESATPOS], $
        (*(*pState).CHANGESATLINE)[1,(*pState).CHANGESATPOS], $
        (*(*pState).CHANGESATLINE)[2,(*pState).CHANGESATPOS]]
        
      ll = XYZTOLL(xyz[0], xyz[1], xyz[2])
      (*pState).OSATELLITE1->SCALE, scale, scale, scale
      (*pState).OSATELLITE1->ROTATE, [1,0,0], -ll[0]+90
      (*pState).OSATELLITE1->ROTATE, [0,0,1], ll[1]+180
      (*pState).OSATELLITE1->TRANSLATE, xyz[0], xyz[1], xyz[2]
      (*pState).CHANGESATPOS += 1
      IF (*pState).CHANGESATPOS EQ 298 THEN (*pState).CHANGESATPOS = 0
      (*pState).OEARTHMODEL->ROTATE,[0,1,0],-0.05
      
      ; 刷新图形
      (*pState).OWINDOW->DRAW, (*pState).OVIEW
      
      WIDGET_CONTROL, ev.ID, Timer = (*pState).TIMER
      
    END
    
    ELSE:
  ENDCASE
END
PRO SATELLITE_DEMO_INITVIEW, dims, oView
  CATCH, error_status
  IF Error_status NE 0 THEN RETURN
  aspect = FLOAT(dims[0])/dims[1]
  myview = [-2.0,-2.0,4.0,4.0]*0.5
  IF (aspect GT 1) THEN BEGIN
    myview[0] = myview[0] - ((aspect-1.0)*myview[2])/2.0
    myview[2] = myview[2] * aspect
  ENDIF ELSE BEGIN
    myview[1] = myview[1] - (((1.0/aspect)-1.0)*myview[3])/2.0
    myview[3] = myview[3] / aspect
  ENDELSE
  oView->SETPROPERTY, VIEWPLANE_RECT=myview
END

PRO SATELLITE_DEMO,wDrawID

  COMPILE_OPT IDL2
  CATCH, error_status
  IF Error_status NE 0 THEN RETURN
  rootDir = FILE_DIRNAME(ROUTINE_FILEPATH('Satellite_demo'))
  DEFSYSV, '!SYSDIR', rootDir
  
  wTopBase = WIDGET_BASE(Title = ' ' , $
    map=0 )
  wBase = WIDGET_BASE(wTopBase, /Row, UName='TIMER', Space = 2)
  WIDGET_CONTROL, wTopBase, /Realize
  
  WIDGET_CONTROL, wDrawID, Get_Value = oWindow
  oWindow->SETPROPERTY, Quality = 2
  oWindow->GETPROPERTY, dimension = dims
  ;初始化
  oView = OBJ_NEW('IDLgrView', COLOR=[0,0,0], PROJECTION=2, EYE=22 , $
    ZCLIP=[2.0,-2.0]*10,dimension = dims)
  ;
  SATELLITE_DEMO_INITVIEW,dims,oView
  
  oTopModel = OBJ_NEW('IDLgrModel')
  ;Creat
  oContainer = OBJ_NEW('IDLgrContainer')
  ;环境光
  oLight0 = OBJ_NEW('IDLgrLight',COLOR=[255,255,255],$
    TYPE=0, INTENSITY=0.5)
  ;太阳光
  oLIght1 = OBJ_NEW('IDLgrLight', loc=[4,0,0],DIRECTION=[-1, 0, 0], COLOR=[255,255,255],$
    TYPE=2,cone=80, INTENSITY=1.25,focus=0)
  ;视觉效果光
  oLIght2 = OBJ_NEW('IDLgrLight',loc=[0,0,3],DIRECTION=[0, 0, -1], COLOR=[255,255,255],$
    TYPE=2,cone=80, INTENSITY=.5,focus=0)
    
  oTopModel->ADD, olight0
  oTopModel->ADD, olight1
  oTopModel->ADD, olight2
  
  ;创建地球
  oEarthModel = CREATEEARTH(oContainer)
  oEarthModel->ROTATE, [1,0,0],  -90
  oEarthModel->ROTATE, [0,1,0], 180
  oTopModel->ADD, oEarthModel
  
  ;创建天空
  oSkyModel = CREATESKY(oContainer)
  oSkyModel->ROTATE, [1,0,0],  -30
  oEarthModel->ADD, oSkyModel
  oView->ADD, oTopModel
  
  
  
  ;状态量
  sState = { $
    wTopBase    :   wBase           , $  ; Top level base IDs
    oView       :   oView           , $  ; View object
    oWindow     :   oWindow         , $  ; Window object
    
    oContainer  :   oContainer      , $  ; Container object
    oTopModel   :   oTopModel       , $  ; Top model
    oEarthModel :   oEarthModel     , $
    oSkyModel   :   oSkyModel       , $
    timer       :   0.05            , $
    oSatellite1 :   OBJ_NEW()       , $
    oPositionSatModel:OBJ_NEW()     , $ ;定点卫星    ;==================
    
    changeSatLine:  PTR_NEW()      , $
    changeSatLine1: PTR_NEW()     , $
    changeSatPos:   0               , $
    changeSatPos1:  0          , $
    timetext1   :   OBJ_NEW()      $
    }
    
  time = SYSTIME()
  time = (STRSPLIT(time , ' ' , /Extract))[3]
  
  sState.TIMETEXT1 = OBJ_NEW('IDLgrText', time, $
    depth_test_disable=1, $
    font = OBJ_NEW('IDLgrFont', 'Times New Roman', size=30), $
    color=[0,0,0]/1.2)
    
  timeModel1 = OBJ_NEW('IDLgrModel')
  timeModel1->ADD,sState.TIMETEXT1
  timeModel1->TRANSLATE, 0.5, -0.8, 0
  oView->ADD, timeModel1
  
  ;创建定点卫星
  oPositionSatModel = CREATESAT(oContainer)
  oEarthModel->ADD, oPositionSatModel
  ll = [40,113,0.9]
  xyz = LLTOXYZ(ll[0],180-ll[1],ll[2])
  scale = 1.8
  oPositionSatModel->SCALE, scale, scale, scale
  oPositionSatModel->ROTATE, [1,0,0], ll[0]
  oPositionSatModel->ROTATE, [0,0,1], ll[1]-90
  oPositionSatModel->TRANSLATE, xyz[0], xyz[1], xyz[2]
  
  sState.OPOSITIONSATMODEL = oPositionSatModel
  
  ;创建卫星轨道线
  oOrbitModel = CREATEORBIT(oContainer, sState, Data=data, R = 0.9, Color = [0,255,0])
  oTopModel->ADD, oOrbitModel
  
  ;创建卫星
  oSatellite1 = CREATESAT(oContainer, Color=[255,0,0])
  oTopModel->ADD, oSatellite1
  ll = [90,116,0.9]
  xyz = LLTOXYZ(ll[0],180-ll[1],ll[2])
  oSatellite1->ROTATE, [1,0,0], -ll[0]+90
  oSatellite1->ROTATE, [0,0,1], ll[1]-10
  oSatellite1->TRANSLATE, xyz[0], xyz[1], xyz[2]
  sState.OSATELLITE1 = oSatellite1
  
  ;将整个视景略作偏移
  oTopModel->ROTATE,[0,1,0], -170
  oTopModel->ROTATE,[1,0,0], 25
  
  ;绘制视景
  oWindow ->DRAW, oView
  
  WIDGET_CONTROL,wBase,/timer
  WIDGET_CONTROL, wTopBase, Set_UValue = PTR_NEW(sState, /No_Copy)
  
  XMANAGER, 'EarthSim', wTopBase, /No_Block
  
END


PRO TEST
  ;
  wTlb = WIDGET_BASE()
  wDraw = WIDGET_DRAW(wtlb,$
    xSize = 800,$
    ySize = 800, $
    retain=0,$
    graphics_level = 2)
  WIDGET_CONTROL, wTlb,/real
  ;
  SATELLITE_DEMO,wDraw
  
;SATELLITE_DEMO,wDraw
  
  
END