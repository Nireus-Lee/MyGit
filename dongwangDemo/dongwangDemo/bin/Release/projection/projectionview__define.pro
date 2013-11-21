

;+
; :Description:
;    CLEANUP.
;-
PRO ProjectionView::Cleanup
  COMPILE_OPT idl2

  self->Idlgrview::cleanup
END

;+
; :Description:
;    SetProperty.
;-
PRO ProjectionView::SetProperty, $
    Imageinfo = imageinfo, $
    ImgLoc=imgLoc, $
    ResetDelta=resetDelta, $
    _Ref_Extra = _extra
  COMPILE_OPT idl2

  IF N_ELEMENTS(imageinfo) GT 0 THEN BEGIN
    self->Deleteall
    self.initFlag=1
    self.uvRange = imageinfo.(1)
    self->Initview
    self->Initimage, imageinfo
    self->Initpolygon, imageinfo.(2)
  ENDIF

  IF N_ELEMENTS(imgLoc) GT 0 THEN BEGIN
    oImage = self.oImgModel->Get(isa='IDLgrImage')
    oImage->Setproperty, location=imgLoc
  END

  IF N_ELEMENTS(resetDelta) GT 0 THEN BEGIN
    oImage = self.oImgModel->Get(isa='IDLgrImage')
    oImage->Setproperty, location=[self.uvRange[0:1],5]
  ENDIF

  self->Idlgrview::setproperty, _Extra = _extra
END

;+
; :Description:
;    GetProperty.
;-
PRO ProjectionView::GetProperty, $
    ImgLoc=imgLoc, $
    Delta=delta, $
    initFlag = initFlag, $
    _Ref_Extra = _extra
  COMPILE_OPT idl2

  IF ARG_PRESENT(imgLoc) THEN BEGIN
    oImage = self.oImgModel->Get(/all, isa='IDLgrImage', count=count)
    IF count GT 0 THEN oImage->Getproperty, location=imgLoc
  ENDIF

  IF ARG_PRESENT(delta) THEN BEGIN
    oImage = self.oImgModel->Get(/all, isa='IDLgrImage', count=count)
    IF count GT 0 THEN BEGIN
      oImage->Getproperty, location=imgLoc
      delta = imgLoc-self.uvRange[0:1]
    ENDIF ELSE delta=[0,0]
  ENDIF

  IF ARG_PRESENT(initFlag) THEN initFlag = self.initFlag

  self->Idlgrview::getproperty, _Extra = _extra
END

;+
; :Description:
;    ����ڲ�����.
;-
PRO ProjectionView::DeleteAll
  COMPILE_OPT idl2

  objs = self.oImgModel->Get(/all, count=count)
  FOR i=0,count-1 DO OBJ_DESTROY, objs
  objs = self.oPolyModel->Get(/all, count=count)
  FOR i=0,count-1 DO OBJ_DESTROY, objs
END

;+
; :Description:
;    ��ʼ��ͼ����ʾ.
;-
PRO ProjectionView::InitImage,sMap,uvrange
  COMPILE_OPT idl2
  ;;��ȡͼ������

  READ_JPEG, self.image, data

  red0 = REFORM(data[0,*,*])
  green0 = REFORM(data[1,*,*])
  blue0 = REFORM(data[2,*,*])

  ;ת��ͼ��ľ�γ�ȷ�Χ���ض���ͶӰ��
  red1 = Map_proj_image( red0, MAP_STRUCTURE=sMap, $
    [-180, -90, 180, 90]  , $
    XINDEX=xindex, YINDEX=yindex )
  green1 = Map_proj_image( green0, XINDEX=xindex, YINDEX=yindex )
  blue1 = Map_proj_image( blue0, XINDEX=xindex, YINDEX=yindex )
  ;
  data[0,*,*] = red1
  data[1,*,*] = green1
  data[2,*,*] = blue1

  uRange = uvRange[2]-uvRange[0]
  vRange = uvRange[3]-uvRange[1]

  ;���ͼ�����
  self.oImgModel->Add, OBJ_NEW('IDLgrImage', $
    data= data, $
    dimensions=[uRange,vRange], $
    location=[uvRange[0:1],3]   )

END

;+
; :Description:
;    ��ʼ��ʸ����ʾ.
;-
PRO ProjectionView::InitPolygon, sMap
  COMPILE_OPT idl2
  ;
  color = [[255,0,0],[200,200,0]]
  FOR ii=0,1 DO BEGIN
    shapeFile = OBJ_NEW('IDLffShape', (self.shpFile)[ii])
    shapeFile->Getproperty, N_Entities = nEntities

    FOR i=0, nEntities-1 DO BEGIN
      entitie = shapeFile->Getentity(i)
      if ptr_valid(entitie.measure) then begin
      	help,'adf'
      endif
      IF PTR_VALID(entitie.parts) NE 0 THEN BEGIN
        cuts = [*entitie.parts, entitie.n_vertices]
        FOR j=0, entitie.n_parts-1 DO BEGIN
          tempLon = (*entitie.vertices)[0,cuts[j]:cuts[j+1] - 1]
          tempLat = (*entitie.vertices)[1,cuts[j]:cuts[j+1] - 1]

          vert = MAP_PROJ_FORWARD([tempLon,tempLat], $
            Map_Structure = sMap, $
            Polylines = polyLines)
          IF N_ELEMENTS(vert) GT 2 THEN BEGIN
            tempPlot = OBJ_NEW('IDLgrPolyline', $
              vert[0,*], $
              vert[1,*], $
              LONARR(1,N_ELEMENTS(vert[0,*]))+9, $
              Polylines = polyLines    , $
              Alpha_Channel = 1, $
              color = color[*,ii])
            self.oPolyModel->Add,tempPlot
          ENDIF
        ENDFOR
      ENDIF
      shapeFile->Destroyentity, entitie
    ENDFOR

    OBJ_DESTROY, shapeFile
  ENDFOR

END

;+
; :Description:
;    ����view����.
;-
PRO ProjectionView::InitView,sMap
  COMPILE_OPT idl2
  ;������

  processBar = Idlitwdprogressbar( $
    GROUP_LEADER=self.tlb, $
    TIME=0,$
    TITLE='ͶӰת����...���Ե�')

  self->Deleteall
  ;ϵͳ��ʾ��Χ
  range = [-90,-180, 90,  180]

  ;����ϵͳ����ϵ
  tempArr = BYTARR(2,2)

  ;��������ʾ

  tempArr = Map_proj_image(tempArr , $
    [-180, -90, 180, 90]    , $
    Map = sMap, $
    UVrange = uvrange   )

  tempArr = 0B
  self.uvrange = uvrange
  ;
  self->Getproperty, dimensions=vd
  uRange = self.uvRange[2]-self.uvRange[0]
  vRange = self.uvRange[3]-self.uvRange[1]

  xrate = DOUBLE(vd[0])/uRange
  yrate = DOUBLE(vd[1])/vRange
  vp = DBLARR(4)
  IF xrate GT yrate THEN BEGIN
    vp[3] = vRange
    vp[2] = DOUBLE(vd[0])/vd[1]*vp[3]
    vp[1] = self.uvRange[1]
    vp[0] = self.uvRange[0]-(vp[2]-uRange)/2.
  ENDIF ELSE BEGIN
    vp[2] = uRange
    vp[3] = DOUBLE(vd[1])/vd[0]*vp[2]
    vp[0] = self.uvRange[0]
    vp[1] = self.uvRange[1]-(vp[3]-vRange)/2.
  ENDELSE
  self->Setproperty, viewplane_rect=vp
  ;��������ʾ
  Idlitwdprogressbar_setvalue, processBar, 20

  ;ת��ͼ��ľ�γ��
  self->Initimage,sMap,uvrange
  ;��������ʾ
  Idlitwdprogressbar_setvalue, processBar, 70
  ;ת��ʸ���ľ�γ��
  self->Initpolygon,sMap
  ;  ��������ʾ
  Idlitwdprogressbar_setvalue, processBar, 100
  WIDGET_CONTROL,processBar,/Destroy
  self.initFlag = 1

END

;+
; :Description:
;    ����ͼ��.
;-
PRO ProjectionView::ConfigureLayer
  COMPILE_OPT idl2

  self.oImgModel = OBJ_NEW('IDLgrModel',depth_test_disable=2)
  self.oPolyModel = OBJ_NEW('IDLgrModel',depth_test_disable=2)

  self->Add, self.oImgModel
  self->Add, self.oPolyModel
END

;+
; :Description:
;    INIT.
;-
FUNCTION ProjectionView::Init, $
    tlb = tlb, $
    ShpFile = shpFile, $
    image = image , $
    _Extra=extra
  COMPILE_OPT idl2

  IF (self->Idlgrview::init(_Extra=extra) NE 1) THEN RETURN, 0

  IF N_ELEMENTS(shpFile) GT 0 THEN self.shpFile = shpFile
  self.tlb = tlb
  self.image = image

  self->Configurelayer

  RETURN, 1
END
;
;----------------------------------------------------------------------------
;+
; ProjectionParameter__Define
;-
PRO Projectionview__define
  COMPILE_OPT idl2
  void = {ProjectionView, $
    INHERITS IDLgrView      , $
    image : ''   ,  $
    tlb         : 0L, $
    initFlag    : 0 , $
    oImgModel   : OBJ_NEW() , $
    oPolyModel  : OBJ_NEW() , $
    shpFile     : STRARR(2) , $
    uvRange     : DBLARR(4) $
    }

END
;
;
;