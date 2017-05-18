PRO ES3_Browse_extensions_init
compile_opt idl2

e = envi(/current)
e.AddExtension, 'Get AWS S3 Data', 'envi_gets3data'

END

FUNCTION StageS3Data, OUTDIR=outdir, $
  ACCESSKEY=accesskey, $
  SECRETKEY=secretkey, $
  BUCKET=bucketName, $
  KEY=key, $
  FILE=file, $
  COLLECT=collect, $
  STATUSLABEL = statuslabel

compile_opt idl2

  e = envi(/current)
  if (e eq !NULL) then e = envi(/headless)

  usestatus = !FALSE
  if (n_elements(statuslabel) eq 1) then begin
    if (widget_info(statuslabel, /VALID)) then usestatus=!TRUE
  endif

  v = e.preferences["directories and files:extensions directory"]
  extensionsDir = v.value
  s3ToolsPython = extensionsDir + 'cso_s3utils.py'
  if (not file_test(s3ToolsPython)) then begin
    err = 'ERROR opening required python library '+s3ToolsPython
    if (usestatus) then widget_control, statuslabel, SET_VALUE=err
    print, 'ERROR opening required python library '+s3ToolsPython
    return, !NULL
  endif

  ; restore the python library
  !NULL = Python.run('execfile(r"'+s3ToolsPython+'")')

  credentialString = '"'+accessKey+'","'+secretKey+'"'
  ; handle the case where this is just a single file

  retVal = !NULL

  if (n_elements(outdir) eq 0) then begin
    outdir = file_dirname(filepath('test.dat', /TMP))
  endif else begin
    if (not file_test(outdir)) then begin
      file_mkdir, outdir
    endif
  endelse

  if (keyword_set(file)) then begin

    localFile = outdir + path_sep() + file_basename(key)
    if (usestatus) then widget_control, statuslabel, SET_VALUE = 'Local File stored in '+localFile
    print, 'Local File stored in '+localFile
    if (usestatus) then widget_control, statuslabel, SET_VALUE = 'Getting '+key
    print, 'Getting '+key
    !NULL = Python.run('getKeyToFile("'+bucketName+'","'+key+'",r"'+localFile+'",'+credentialString+')')
    retVal = localFile

  endif else if (keyword_set(collect)) then begin
    collectName = file_basename(key)
    localDir = outdir+path_sep()+collectName
    if (not file_test(localDir, /DIR)) then begin
      file_mkdir, localDir
    endif

    print, 'Collect Stored in '+localDir
    !NULL = Python.run('files = getS3FileList("'+bucketName+'","'+key+'",'+credentialString+')')
    files = Python.files

    ; get the files in the collect from S3
    foreach keyName, files do begin
      localFile = localDir+path_sep()+file_basename(keyName)
      if (usestatus) then widget_control, statuslabel, SET_VALUE = 'Getting '+keyName
      print, 'Getting '+keyName
      !NULL = Python.run('getKeyToFile("'+bucketName+'","'+keyName+'",r"'+localFile+'",'+credentialString+')')
    endforeach
    retval = localDir

  endif

  return, retval

END


PRO ES3_Browse, event

compile_opt idl2
widget_control, event.top, GET_UVALUE = state

dir = dialog_pickfile(/DIR, TITLE='Select Directory for S3 Output', /MUST_EXIST)
if (dir ne '') then begin
  widget_control, state.outDirText, SET_VALUE = dir[0]
endif

END

PRO ES3_SingleFile , event

  compile_opt idl2
  widget_control, event.top, GET_UVALUE = state
  
  if (event.select) then begin
      state.singleFile = !TRUE
      widget_control, state.openInENVIButton, SENSITIVE=1
  endif
  
END

PRO ES3_Collect , event

  compile_opt idl2
  widget_control, event.top, GET_UVALUE = state

  if (event.select) then begin
    state.singleFile = !FALSE
    widget_control, state.openInENVIButton, SENSITIVE=0
  endif
END

PRO ES3_OpenInEnvi , event

  compile_opt idl2
  widget_control, event.top, GET_UVALUE = state
  
  if (event.select) then begin
      state.openInENVI = !TRUE
  endif else begin
      state.openInENVI = !FALSE
  endelse

END

PRO ES3_GetData , event

  compile_opt idl2
  widget_control, event.top, GET_UVALUE = state
  
  validInput = !TRUE
  
  ; collect/validate inputs
  widget_control, state.accessKeyText, GET_VALUE = tmp
  if (tmp[0] eq '') then begin
    a = dialog_message('Must provide an access key')
    validInput = !FALSE
  endif else accessKey = strtrim(tmp[0],2)
  
  widget_control, state.secretKeyText, GET_VALUE = tmp
  if (tmp[0] eq '') then begin
    a = dialog_message('Must provide a secret key')
    validInput = !FALSE
  endif else secretKey = strtrim(tmp[0],2)

  widget_control, state.bucketNameText, GET_VALUE = tmp
  if (tmp[0] eq '') then begin
    a = dialog_message('Must provide bucket name')
    validInput = !FALSE
  endif else bucketName = strtrim(tmp[0],2)
  
  widget_control, state.keyNameText, GET_VALUE = tmp
  if (tmp[0] eq '') then begin
    a = dialog_message('Must provide a key name')
    validInput = !FALSE
  endif else keyName = strtrim(tmp[0],2)
  
  widget_control, state.outDirText, GET_VALUE = tmp
  if (tmp[0] eq '') then begin
    a = dialog_message('Must provide an output directory')
    validInput = !FALSE
  endif else outDir = strtrim(tmp[0],2)
  
  if (validInput) then begin
       
       if (state.singleFile) then begin
            r = stages3data(outdir=outdir, accesskey = accesskey, secretkey = secretkey, $
              bucket = bucketName, key = keyName, /FILE, STATUSLABEL=state.statuslabel)
            if (state.openInENVI) then begin
                e = envi(/current)
                if (e eq !NULL) then begin
                   a = dialog_message('ENVI is not running', /ERROR)
                endif else begin
                   r = e.openRaster(r)
                   v = e.getView()
                   l = v.createLayer(r)
                endelse
            endif
       endif else begin
            r = stages3data(outdir=outdir, accesskey = accesskey, secretkey = secretkey, $
              bucket = bucketName, key = keyName, /COLLECT, STATUSLABEL=state.statuslabel)
       endelse
       widget_control, state.statuslabel, SET_VALUE='Ready'
       
       
  endif
  
END



PRO ENVI_GetS3Data

compile_opt idl2

tlb = widget_base(TITLE = 'AWS S3 Data Access', /COLUMN, TAB_MODE=1)
topRow = widget_base(tlb, /ROW)
accessKeyLabel = widget_label(topRow, VALUE = 'Access Key: ')
accessKeyText = widget_text(topRow, XSIZE=25, YSIZE=1, /EDITABLE, TAB_MODE=1)

row1 = widget_base(tlb, /ROW)
secretKeyLabel = widget_label(row1, VALUE = 'Secret Key: ')
secretKeyText = widget_text(row1, XSIZE=45, YSIZE=1, /EDITABLE, TAB_MODE=1)

row2 = widget_base(tlb, /ROW)
bucketNameLabel = widget_label(row2, VALUE='Bucket Name: ')
bucketNameText = widget_text(row2, XSIZE = 30, YSIZE=1, /EDITABLE, TAB_MODE=1)

row3 = widget_base(tlb, /ROW)
keyNameLabel = widget_label(row3, VALUE='Key Name: ')
keyNameText = widget_text(row3, XSIZE=40, YSIZE=1, /EDITABLE, TAB_MODE=1)
row3a = widget_base(row3, /EXCLUSIVE, /ROW)
fileButton = widget_button(row3a, VALUE='Single File', EVENT_PRO='ES3_SingleFile' ,/NO_RELEASE)
collectButton = widget_button(row3a, VALUE='Entire Collect', EVENT_PRO = 'ES3_Collect', /NO_RELEASE)

row4 = widget_base(tlb, /ROW)
outDirLabel = widget_label(row4, VALUE = 'Output Directory: ')
outDirText = widget_text(row4, XSIZE=50, YSIZE=1, /EDITABLE, VALUE=file_dirname(filepath('',/TMP)), TAB_MODE=1)
outDirBrowse = widget_button(row4, VALUE=filepath('open.bmp',SUBDIR=['resource','bitmaps']), /BITMAP, $
  EVENT_PRO='ES3_Browse')
  

actionBase = widget_base(tlb, /ROW)
getDataButton = widget_button(actionBase, VALUe = 'Get Data', EVENT_PRO = 'ES3_GetData', TAB_MODE=1)
actionBaseA = widget_Base(actionBase, /ROW, /NONEXCLUSIVE)
openInENVIButton = widget_button(actionbaseA, VALUE='Open File in ENVI', EVENT_PRO='ES3_OpenInENVI')

bottomBase = widget_base(tlb, /ROW, /FRAME)
statusLabel = widget_label(bottomBase, VALUE = 'Ready', /DYNAMIC_RESIZE)

widget_control, tlb, /REALIZE
widget_control, openInENVIButton, SET_BUTTON=0
widget_control, fileButton, SET_BUTTON=1
widget_control, collectButton, SET_BUTTON=0

state=DICTIONARY("accessKeyText", accessKeyText, $
                 "secretKeyText", secretKeyText, $
                 "keyNameText", keyNameText, $ 
                 "bucketNameText", bucketNameText, $
                 "singleFile", !TRUE, $
                 "outDirText", outDirText, $
                 "openInENVIButton", openInENVIButton, $
                 "openInENVI", !FALSE, $
                 "statusLabel", statusLabel)
                 
widget_control, tlb, SET_UVALUE=state

Xmanager, 'envi_gets3data', tlb, /NO_BLOCK


END         