using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.IO;
using Windows7.Multitouch;
using Windows7.Multitouch.Win32Helper;
using System.Threading;
using Microsoft.Win32;

namespace dongwangDemo
{
    public partial class FormMain : Form
    {
        #region Global Variable
        // Create a touch handler.
        //private TouchHandler touchHandler;
        private GestureHandler gestureHandler;

        // 缩放相关
        private double zoomMoveLeftRate = 0.0d;
        private double zoomMoveTopRate = 0.0d;

        // 平移相关
        private int panInPanelBeginLeft = 0;    // 它的世界坐标X
        private int panInPanelBeginTop = 0;     // 它的世界坐标Y
        private int oldPicLeft = 0;             // 平移开始世界坐标X
        private int oldPicTop = 0;              // 平移开始世界坐标Y
        #endregion

        // 配置文件路径
        private string strIniPath = "";
        // 概要路径
        private string strTechSummaryPath = "";
        // 图片路径
        private string strTechPicturePath = "";
        // 文档路径
        private string strTechDocumentPath = "";

        // 存储行业按钮
        private List<Button> lstBtnIndustry = null;
        // 存储技术按钮
        private List<Button> lstBtnTech = null;
        // 最后点击的行业按钮
        private Button btnLast = null;
        // 最后点击的技术按钮
        private Button btnLastTec = null;

        // 加载的图片资源
        private Bitmap sourcePic = null;

        // 控制方向键矩形区域
        private Rectangle rectTop = new Rectangle(23, 0, 28, 26);
        private Rectangle rectBottom = new Rectangle(23, 49, 28, 25);
        private Rectangle rectLeft = new Rectangle(0, 26, 26, 23);
        private Rectangle rectRight = new Rectangle(48, 26, 26, 23);
        private Point pointHover = new Point(0, 0);
        private bool isDownInPicResources = false;

        #region 自动播放相关
        // 是否自动播放
        private bool isAuto = false;
        // 自动播放到的位置
        private int autoPosIndustry = -1;
        private int autoPosTech = -1;
        // 是否进入下一行业, 初始值 true
        private bool isNext = true; 
        #endregion

        #region flash控制
        // 是否是播放中
        private bool isFlashPlay = false;
        #endregion

        /// <summary>
        /// 构造
        /// </summary>
        public FormMain()
        {
            InitializeComponent();
        }

        //关闭IDL控件
        private void closeIDL()
        {
            this.axIDLDrawWidget1.DestroyDrawWidget();
            this.picBoxSource.Visible = true;
            this.btnZoomOut.Visible = true;
            this.btnZoomIn.Visible = true;
            this.btnReset.Visible = true;
            this.picMove.Visible = true;  

        }
        /// <summary>
        /// 窗体load
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void FormMain_Load(object sender, EventArgs e)
        {
            this.init();
            //读取注册表获取IDL8.0或IDL7.1或IDL7.0的目录
            RegistryKey rsg = null;

            rsg = Registry.LocalMachine.OpenSubKey("SOFTWARE\\ITT\\IDL\\7.0", true);

            if (rsg.GetValue("InstallDir") != null) //读取失败返回null
            {
                //初始化IDL80路径
                axIDLDrawWidget1.IdlPath = Path.Combine(rsg.GetValue("InstallDir").ToString(), @"IDL70\bin\bin.x86\idl.dll");

            }
           
        }

        /// <summary>
        /// 初始化
        /// </summary>
        private void init()
        {
            #region 添加按钮到list中
            // 添加按钮到list中
            this.lstBtnIndustry = new List<Button>();
            this.lstBtnIndustry.Add(this.btn_GTZY);
            this.lstBtnIndustry.Add(this.btn_HJBH);
            this.lstBtnIndustry.Add(this.btn_CXJS);
            this.lstBtnIndustry.Add(this.btn_KCKC);
            this.lstBtnIndustry.Add(this.btn_SLSW);
            this.lstBtnIndustry.Add(this.btn_LYZY);
            this.lstBtnIndustry.Add(this.btn_HYYY);
            this.lstBtnIndustry.Add(this.btn_JTGL);
            this.lstBtnIndustry.Add(this.btn_XDNY);
            this.lstBtnIndustry.Add(this.btn_XXTJ);
            this.lstBtnTech = new List<Button>();
            this.lstBtnTech.Add(this.btn_tec1);
            this.lstBtnTech.Add(this.btn_tec2);
            this.lstBtnTech.Add(this.btn_tec3);
            this.lstBtnTech.Add(this.btn_tec4);
            this.lstBtnTech.Add(this.btn_tec5);
            this.lstBtnTech.Add(this.btn_tec6);
            #endregion

            // 设置所有技术按钮不可用
            this.SetBtnEnable(false);

            // 初始化图片尺寸
            this.picBoxSource.Width = this.palSource.Width;
            this.picBoxSource.Height = this.palSource.Height;

            // 初始化字体
            this.initFont();

            #region 初始化flash控件
            // 初始化flash控件
            this.flashPlayer.Width = this.palSource.Width;
            this.flashPlayer.Height = this.palSource.Height;
            this.flashPlayer.Left = 0;
            this.flashPlayer.Top = 0;
            this.flashPlayer.Visible = false;
            #endregion

            // 设置flash播放、暂停btnPlay按钮，父亲
            this.btnPlay.Parent = this.flashPlayer;

            // 初始化右下角GIF
            this.picWX.Image = Properties.Resources.wx;
            // 初始化GF - GIF
            this.picGF.Image = Properties.Resources.gf;

            #region 初始化触控
            // 初始化触控
            //检查是否有触控设备
            if (GestureHandler.DigitizerCapabilities.IsMultiTouchReady)
            {
                gestureHandler = Factory.CreateHandler<GestureHandler>(this.picBoxSource.Handle);
                gestureHandler.ZoomBegin += new EventHandler<GestureEventArgs>(ZoomBegin_Process);
                gestureHandler.Zoom += new EventHandler<GestureEventArgs>(Zoom_Process);
                gestureHandler.PanBegin += new EventHandler<GestureEventArgs>(PanBegin_Process);
                gestureHandler.Pan += new EventHandler<GestureEventArgs>(Pan_Process);
                gestureHandler.PanEnd += new EventHandler<GestureEventArgs>(PanEnd_Process);
            }
            else
            {
                // Tell the user there is no touch device available.
                MessageBox.Show("未发现触控设备！");
            }
            #endregion

            // 读取配置文件信息
            this.readConfig();
        }

        /// <summary>
        /// 初始化字体
        /// </summary>
        private void initFont()
        {
            Rectangle rect = new Rectangle();
            rect = Screen.GetWorkingArea(this);
            int screenWidth = rect.Width;//屏幕宽
            int screenHeight = rect.Height;//屏幕高
            // 上面的  技术 按钮字体
            Font fontTechBtn = null;
            if (screenWidth <= 1440)
            {
                fontTechBtn = new Font("微软雅黑", 9, FontStyle.Regular);
            }
            else
            {
                fontTechBtn = new Font("微软雅黑", 12, FontStyle.Regular);
            }
            foreach (Button btn in this.lstBtnTech)
            {
                btn.Font = fontTechBtn;
            }

            // 其他文本字体
            Font fontText = null;
            if (screenWidth <= 1440)
            {
                fontText = new Font("微软雅黑", 13.5f, FontStyle.Regular);
            }
            else
            {
                fontText = new Font("微软雅黑", 15.75f, FontStyle.Regular);
            }
            this.btnRecord.Font = fontText;
            this.btnQuit.Font = fontText;
            this.btnAuto.Font = fontText;
            this.lblCom.Font = fontText;
            this.lblWX.Font = fontText;
        }

        /// <summary>
        /// 读取配置文件信息
        /// </summary>
        private void readConfig()
        {
            string ret = null;
            #region 缩放率
            // 缩放率
            ret = Common.ReadIniValue("Config", Common.INI_KEY_ZOOM_RATE, Common.strAppPath + Common.INI_CONFIG_PATH);
            try
            {
                Common.zoomRate = Convert.ToInt32(ret);
                if (Common.zoomRate < 5 || Common.zoomRate > 90)
                {
                    Common.zoomRate = 20;
                }
            }
            catch (FormatException e)
            {
                Common.zoomRate = 20;
                Console.WriteLine(e.Message);
            }
            #endregion

            #region 自动播放频率
            // 自动播放频率
            ret = Common.ReadIniValue("Config", Common.INI_KEY_AUTO_RATE, Common.strAppPath + Common.INI_CONFIG_PATH);
            try
            {
                Common.autoRate = Convert.ToInt32(ret) * 1000;
                if (Common.autoRate <= 1 * 1000 || Common.autoRate >= 200 * 1000)
                {
                    Common.autoRate = 20 * 1000;
                }
            }
            catch (FormatException exc)
            {
                Common.autoRate = 20 * 1000;
                Console.WriteLine(exc.Message);
            }
            this.timerAuto.Interval = Common.autoRate;
            #endregion

            #region 移动百分比频率
            // 移动百分比频率
            ret = Common.ReadIniValue("Config", Common.INI_KEY_MOVE_RATE, Common.strAppPath + Common.INI_CONFIG_PATH);
            try
            {
                Common.moveRate = Convert.ToInt32(ret);
                if (Common.moveRate < 1 || Common.moveRate >= 10)
                {
                    Common.moveRate = 3;
                }
            }
            catch (FormatException exc)
            {
                Common.moveRate = 3;
                Console.WriteLine(exc.Message);
            }
            #endregion
        }

        /// <summary>
        /// 缩放手势开始
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void ZoomBegin_Process(object sender, GestureEventArgs e)
        {
            // 缩放中心点比率
            this.zoomMoveLeftRate = (double)e.Center.X / this.picBoxSource.Width;
            this.zoomMoveTopRate = (double)e.Center.Y / this.picBoxSource.Height;
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }

        /// <summary>
        /// 缩放手势中
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void Zoom_Process(object sender, GestureEventArgs e)
        {
            // 计算变化后
            double zoomWidth = this.picBoxSource.Width * e.ZoomFactor;
            double zoomHeight = this.picBoxSource.Height * e.ZoomFactor;
            // 更新位置  和   尺寸
            //this.picBoxSource.Left = (int)((double)(this.picBoxSource.Left) - this.zoomMoveLeftRate * (zoomWidth - this.picBoxSource.Width));
            //this.picBoxSource.Top = (int)((double)(this.picBoxSource.Top) - this.zoomMoveTopRate * (zoomHeight - this.picBoxSource.Height));
            this.picBoxSource.Left -= ((int)(zoomWidth - this.picBoxSource.Width) / 2);
            this.picBoxSource.Top -= ((int)(zoomHeight - this.picBoxSource.Height) / 2);
            this.picBoxSource.Width = (int)zoomWidth;
            this.picBoxSource.Height = (int)zoomHeight;
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }

        /// <summary>
        /// 平移手势开始
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void PanBegin_Process(object sender, GestureEventArgs e)
        {
            // 记录图片世界坐标点
            this.panInPanelBeginLeft = e.Location.X + this.picBoxSource.Left;
            this.panInPanelBeginTop = e.Location.Y + this.picBoxSource.Top;
            // 记录图片本身呗点击坐标点
            this.oldPicLeft = this.picBoxSource.Left;
            this.oldPicTop = this.picBoxSource.Top;
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }
        /// <summary>
        /// 平移手势中
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void Pan_Process(object sender, GestureEventArgs e)
        {
            // 平移到的世界坐标点
            int panInPanelMoveLeft = e.Location.X + this.picBoxSource.Left;
            int panInPanelMoveTop = e.Location.Y + this.picBoxSource.Top;
            // 相对世界的移动距离
            int nWidth = panInPanelMoveLeft - this.panInPanelBeginLeft;
            int nHeight = panInPanelMoveTop - this.panInPanelBeginTop;
            // 更新图片位置
            this.picBoxSource.Left = this.oldPicLeft + nWidth;
            this.picBoxSource.Top = this.oldPicTop + nHeight;            
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }
        /// <summary>
        /// 平移手势结束
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void PanEnd_Process(object sender, GestureEventArgs e)
        {
            // 回复控制点数值
            this.panInPanelBeginLeft = 0;
            this.panInPanelBeginTop = 0;
            this.oldPicLeft = 0;
            this.oldPicTop = 0;

            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }
        
        /// <summary>
        /// 双击 - 放大
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void picBoxSource_MouseDoubleClick(object sender, MouseEventArgs e)
        {
            // 放大尺寸
            double divWidth = Common.zoomRate * this.picBoxSource.Width / 100;
            double divHeight = Common.zoomRate * this.picBoxSource.Height / 100;
            // 位置变化值
            double leftPlus = (double)e.X / this.picBoxSource.Width * divWidth;
            double topPlus = (double)e.Y / this.picBoxSource.Height * divHeight;
            // 更新尺寸
            this.picBoxSource.Width = (int)((double)this.picBoxSource.Width + divWidth);
            this.picBoxSource.Height = (int)((double)this.picBoxSource.Height + divHeight);
            // 更新位置
            this.picBoxSource.Left = (int)((double)this.picBoxSource.Left - leftPlus);
            this.picBoxSource.Top = (int)((double)this.picBoxSource.Top - topPlus);
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }

        /// <summary>
        /// 左边  行业按钮点击事件
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btn_Industry_Click(object sender, EventArgs e)
        {
            //将文字说明栏隐藏
            //this.tableLayoutPanel8.Dispose();
            //this.tableLayoutPanel8.Height = 0;

            this.lblDetial.Visible = false;
            this.lblTitle.Visible = false;
            //  是自动播放中，且来自于用户点击
            if (this.isAuto && null != e)
            {
                return;
            }
            // 取得配置文件名称
            this.strIniPath = Common.strAppPath + "Ini\\" + ((Button)sender).Tag.ToString();
           
          


          
         
            // 恢复 技术 按钮的上次已点击
            this.btnLastTec = null;

            // 更新按钮背景
            this.UpdateBtnInduBack(sender);

            // 控制按钮亮暗, 并设置背景颜色
            this.SetBtnEnable();
            
            // 初始化 概要  和  图片
            this.lblTitle.Text = "";
            this.lblDetial.Text = "";
            // 如    不是  自动播放中
            if (!this.isAuto)
            {
               //设置初始图片
                this.picBoxSource.Image = Properties.Resources.init;
                this.picBoxSource.InitialImage = Properties.Resources.init;
                this.picBoxSource.Left = 0;
                this.picBoxSource.Top = 0;
                this.picBoxSource.Width = this.palSource.Width;
                this.picBoxSource.Height = this.palSource.Height/*+this.tableLayoutPanel8.Height*/;
               
                if (false == this.picBoxSource.Visible)
                {
                    this.picBoxSource.Visible = true;
                    this.flashPlayer.Stop();
                    this.flashPlayer.Visible = false;
                }
            }

        }
        
        /// <summary>
        /// 上面  技术按钮点击事件
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btn_Technology_Click(object sender, EventArgs e)
        {
           

            //this.tableLayoutPanel8.Visible = true;
            //  是自动播放中，且来自于用户点击
            if (this.isAuto && null != e)
            {
                return;
            }
           

            // 更新  技术  和  报告 背景色
            this.UpdateBtnTechBack(sender);

            if (null != this.strIniPath && "" != this.strIniPath)
            {
                // 读取配置文件
                this.ReadInfoPath(sender);

                // 显示标题
                string[] ArrayInfo = Common.ReadTxtFile(this.strTechSummaryPath);
                if (null != ArrayInfo && 2 == ArrayInfo.Length)
                {
                    this.lblTitle.Text = ArrayInfo[0];
                    this.lblDetial.Text = ArrayInfo[1];
                    this.lblTitle.Visible = true;
                    this.lblDetial.Visible = true;
                }

                // 显示图片
                this.pictureOpen(this.strTechPicturePath);
            }

            // 报告按钮状态和颜色
            if (File.Exists(this.strTechDocumentPath))
            {
                this.btnRecord.Enabled = true;
                this.btnRecord.BackColor = Common.COL_BTN_REC_NORMAL;
            }

            // 更新上一次按钮引用
            this.btnLastTec = (Button)sender;
            
        }
        
        /// <summary>
        /// 打开 技术 对应图片 或  flash
        /// </summary>
        /// <param name="fileName"></param>
        private void pictureOpen(string fileName)
        {
            //SourcePic
            string FullName = fileName;

            //初始化
            if (this.sourcePic != null)
            {
                this.sourcePic.Dispose();
            }
            ///cbZoom.Text = "100%";
            ///curZoomRate = 1;//当前放缩比率

            if (File.Exists(FullName))
            {
                // 判断打开的文件是否是flash
                if (0 <= FullName.IndexOf(".swf") || 0 <= FullName.IndexOf(".SWF"))
                {
                    this.flashPlayer.Movie = FullName;
                    this.flashPlayer.Visible = true;
                    this.flashPlayer.Play();
                    this.flashPlayer.Visible = true;
                    // 默认值
                    if (false == this.isFlashPlay)
                    {
                        // 设置按钮背景色图片 为  ||
                        this.btnPlay.BackgroundImage = Properties.Resources.icon_pause;  //  ||
                        // 设置标志为自动播放
                        this.isFlashPlay = true;
                    }

                    // 获取文件名
                    int iPos = FullName.LastIndexOf("\\");
                    string strName = FullName.Substring(iPos + 1);
                    strName = strName.Substring(0, strName.Length - 4);
                    string ret = Common.ReadIniValue("Config", strName, Common.strAppPath + Common.INI_CONFIG_PATH);
                    int iInterval = 0;
                    try
                    {
                        iInterval = Convert.ToInt32(ret) * 1000;
                        if (iInterval <= 1000 || iInterval >= 200 * 1000)
                        {
                            iInterval = Common.autoRate;
                        }
                    }
                    catch (FormatException e)
                    {
                        iInterval = Common.autoRate;
                        Console.WriteLine(e.Message);
                    }
                    // 设置自动播放时间 = 文件配置
                    this.timerAuto.Interval = iInterval;

                    // 隐藏图片控件  和  缩放按钮
                    this.picBoxSource.Visible = false;
                    this.btnZoomOut.Visible = false;
                    this.btnZoomIn.Visible = false;
                    this.btnReset.Visible = false;
                    this.picMove.Visible = false;                     
                }
                else
                {
                    this.sourcePic = new System.Drawing.Bitmap(FullName);
                    this.picBoxSource.Image = this.sourcePic;
                    this.picBoxSource.InitialImage = this.sourcePic;
                    this.picBoxSource.Width = this.palSource.Width;
                    this.picBoxSource.Height = this.palSource.Height-this.lblTitle.Height-this.lblDetial.Height;
                    this.picBoxSource.Left = 0;
                    this.picBoxSource.Top = this.lblTitle.Height + this.lblDetial.Height;
                    this.picBoxSource.Visible = true;
                    this.btnZoomOut.Visible = true;
                    this.btnZoomIn.Visible = true;
                    this.btnReset.Visible = true;
                    this.picMove.Visible = true;
                    // 设置自动播放时间 = 设置
                    this.timerAuto.Interval = Common.autoRate;
                    // 隐藏flash控件
                    this.flashPlayer.Stop();
                    this.flashPlayer.Visible = false;
                }
            }
            else
            {
                ///??MessageBox.Show("图片文件<" + fileName + ">不存在!");
            }
        }

        /// <summary>
        /// 读取详细路径信息（概要、图片、文档），并设置
        /// </summary>
        private void ReadInfoPath(object sender)
        {
            string strRet = "";

            #region 读取概要路径
            strRet = Common.ReadIniValue(((Button)sender).Tag.ToString(), Common.INI_KEY_SUMMARY_PATH, this.strIniPath);
            if (Common.READ_INI_ERROR != strRet)
            {
                this.strTechSummaryPath = Common.strAppPath + strRet;
            }
            else
            {
                // 设置默认值
                this.strTechSummaryPath = "";
            }
            #endregion

            #region 读取图片路径
            strRet = Common.ReadIniValue(((Button)sender).Tag.ToString(), Common.INI_KEY_PICTURE_PATH, this.strIniPath);
            if (Common.READ_INI_ERROR != strRet)
            {
                this.strTechPicturePath = Common.strAppPath + strRet;
            }
            else
            {
                // 设置默认值
                this.strTechPicturePath = "";
            }
            #endregion

            #region 读取文档路径
            strRet = Common.ReadIniValue(((Button)sender).Tag.ToString(), Common.INI_KEY_DOCUMENT_PATH, this.strIniPath);
            if (Common.READ_INI_ERROR != strRet)
            {
                this.strTechDocumentPath = Common.strAppPath + strRet;
            }
            else
            {
                // 设置默认值
                this.strTechDocumentPath = "";
            }
            #endregion
        }
        
        /// <summary>
        /// 更新“行业”按钮背景
        /// </summary>
        /// <param name="sender"></param>
        private void UpdateBtnInduBack(object sender)
        {
            // 更新上一次的按钮背景
            if (null != this.btnLast)
            {
                this.btnLast.BackgroundImage = Properties.Resources.menu_hover;
            }
            // 设置点击按钮的背景
            ((Button)sender).BackgroundImage = Properties.Resources.menu_visited;
            // 更新上一次按钮引用
            this.btnLast = (Button)sender;
        }

        /// <summary>
        /// 更新“技术”按钮背景色
        /// </summary>
        /// <param name="sender"></param>
        private void UpdateBtnTechBack(object sender)
        {
            // 更新上一次的按钮背景色
            if (null != this.btnLastTec)
            {
                this.btnLastTec.BackColor = Common.COL_BTN_TEC_NORMAL;
            }
            // 设置点击按钮的背景色
            ((Button)sender).BackColor = Common.COL_BTN_TEC_SELECT;
        }

        /// <summary>
        /// 设置“技术”按钮 和  报告按钮  可不可用
        /// </summary>
        /// <param name="isEnable"></param>
        private void SetBtnEnable(bool isEnable)
        {
            if (isEnable)
            {
                foreach (Button btn in this.lstBtnTech)
                {
                    btn.Enabled = true;
                    btn.BackColor = Common.COL_BTN_TEC_NORMAL;
                }
            }
            else
            {
                foreach (Button btn in this.lstBtnTech)
                {
                    btn.Enabled = false;
                    btn.BackColor = Common.COL_BTN_TEC_UNABLE;
                }
            }
            // 报告按钮状态和颜色
            this.btnRecord.Enabled = false;
            this.btnRecord.BackColor = Common.COL_BTN_REC_UNABLE;
        }

        /// <summary>
        /// 根据配置文件设置“技术”按钮  和  报告按钮  状态
        /// </summary>
        private void SetBtnEnable()
        {
            string strRet = "";

            foreach (Button btn in this.lstBtnTech)
            {
                strRet = Common.ReadIniValue(Common.INI_KEY_BTN_STATUS, btn.Tag.ToString(), this.strIniPath);
                if (Common.READ_INI_ERROR == strRet)
                {
                    btn.Enabled = false;
                    btn.BackColor = Common.COL_BTN_TEC_UNABLE;
                }
                else
                {
                    if (Common.BTN_ENABLE == strRet)
                    {
                        btn.Enabled = true;
                        btn.BackColor = Common.COL_BTN_TEC_NORMAL;
                    }
                    else
                    {
                        btn.Enabled = false;
                        btn.BackColor = Common.COL_BTN_TEC_UNABLE;
                    }
                }
            }

            // 报告按钮状态和颜色
            this.btnRecord.Enabled = false;
            this.btnRecord.BackColor = Common.COL_BTN_REC_UNABLE;
        }

        /// <summary>
        /// 窗体关闭
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void FormMain_FormClosed(object sender, FormClosedEventArgs e)
        {
            if (this.flashPlayer.IsPlaying())
            {
                this.flashPlayer.Stop();
            }
            if (this.isAuto)
            {
                // 停止自动播放
                this.timerAuto.Stop();
            }

            if (null != this.lstBtnIndustry)
            {
                this.lstBtnIndustry.Clear();
            }
            if (null != this.lstBtnTech)
            {
                this.lstBtnTech.Clear();
            }
            
        }

        /// <summary>
        /// 生成报告
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnRecord_Click(object sender, EventArgs e)
        {
            // 如果是自动播放中
            if (this.isAuto)
            {
                return;
            }
            if (File.Exists(this.strTechDocumentPath))
            {
                //生成报告
                System.Diagnostics.Process.Start(strTechDocumentPath);
            }
            else
            {
                MessageBox.Show("报告生成失败，可能文件不存在，请检查目录！");
            }
        }

        /// <summary>
        /// 退出按钮
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnQuit_Click(object sender, EventArgs e)
        {
            this.Close();
            Application.Exit();
        }

        /// <summary>
        /// 图片加载完毕
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void picBoxSource_LoadCompleted(object sender, AsyncCompletedEventArgs e)
        {
            this.btnReset.Image = Properties.Resources.icon_reset_unavailable;
            this.btnReset.Tag = Common.BTN_UNABLE;
        }

        /// <summary>
        /// 放大 按钮
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnZoomOut_Click(object sender, EventArgs e)
        {
            /*
            // 计算当前比率
            double curZoomRateWidth = (double)this.picBoxSource.Width * 100 / this.palSource.Width;
            double curZoomRateHeight = (double)this.picBoxSource.Height * 100 / this.palSource.Height;
            // 增加比率
            curZoomRateWidth += (double)Common.zoomRate;
            curZoomRateHeight += (double)Common.zoomRate;
            // 设置尺寸
            if (curZoomRateWidth < 1000.0d && curZoomRateHeight < 1000.0d)
            {
                this.picBoxSource.Width = (Int32)(this.palSource.Width * curZoomRateWidth / 100);
                this.picBoxSource.Left -= (Int32)((double)this.palSource.Width * Common.zoomRate / 200);
                this.picBoxSource.Height = (Int32)(this.palSource.Height * curZoomRateHeight / 100);
                this.picBoxSource.Top -= (Int32)((double)this.palSource.Height * Common.zoomRate / 200);
            }
            */
            // 放大尺寸
            double divWidth = Common.zoomRate * this.picBoxSource.Width / 100;
            double divHeight = Common.zoomRate * this.picBoxSource.Height / 100;
            // 计算世界中心点在图片上的位置(0-l) + (w/2)
            double leftInWorld = (0.0d - this.picBoxSource.Left) + ((double)this.palSource.Width / 2);
            double topInWorld = (0.0d - this.picBoxSource.Top) + ((double)this.palSource.Height / 2);
            // 位置变化值
            double leftPlus = leftInWorld / this.picBoxSource.Width * divWidth;
            double topPlus = topInWorld / this.picBoxSource.Height * divHeight;
            // 更新尺寸
            this.picBoxSource.Width = (int)((double)this.picBoxSource.Width + divWidth);
            this.picBoxSource.Height = (int)((double)this.picBoxSource.Height + divHeight);
            // 更新位置
            this.picBoxSource.Left = (int)((double)this.picBoxSource.Left - leftPlus);
            this.picBoxSource.Top = (int)((double)this.picBoxSource.Top - topPlus);
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }

        /// <summary>
        /// 还原 按钮
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnReset_Click(object sender, EventArgs e)
        {
            if (Common.BTN_ENABLE == this.btnReset.Tag.ToString())
            {
                // 讲图片位置  和  大小还原
                this.picBoxSource.Width = this.palSource.Width;
                this.picBoxSource.Height = this.palSource.Height;
                this.picBoxSource.Left = 0;
                this.picBoxSource.Top = 0;

                // 设置按钮不可点
                this.btnReset.Image = Properties.Resources.icon_reset_unavailable;
                this.btnReset.Tag = Common.BTN_UNABLE;
            }
        }

        /// <summary>
        /// 缩小 按钮
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnZoomIn_Click(object sender, EventArgs e)
        {
            /*
            // 计算当前比率
            double curZoomRateWidth = (double)this.picBoxSource.Width * 100 / this.palSource.Width;
            double curZoomRateHeight = (double)this.picBoxSource.Height * 100 / this.palSource.Height;
            // 缩小比率
            curZoomRateWidth -= (double)Common.zoomRate;
            curZoomRateHeight -= (double)Common.zoomRate;
            // 设置尺寸
            if (curZoomRateWidth >= 20 && curZoomRateHeight >= 20)
            {
                this.picBoxSource.Width = (Int32)(this.palSource.Width * curZoomRateWidth / 100);
                this.picBoxSource.Left += (Int32)((double)this.palSource.Width * Common.zoomRate / 200);
                this.picBoxSource.Height = (Int32)(this.palSource.Height * curZoomRateHeight / 100);
                this.picBoxSource.Top += (Int32)((double)this.palSource.Height * Common.zoomRate / 200);
            }
            */
            // 计算当前比率, 太小直接返回
            double curZoomRateWidth = (double)this.picBoxSource.Width * 100 / this.palSource.Width;
            double curZoomRateHeight = (double)this.picBoxSource.Height * 100 / this.palSource.Height;
            if (curZoomRateWidth <= 20 || curZoomRateHeight <= 20)
            {
                return;
            }
            // 缩小尺寸
            double divWidth = Common.zoomRate * this.picBoxSource.Width / 100;
            double divHeight = Common.zoomRate * this.picBoxSource.Height / 100;
            // 计算世界中心点在图片上的位置(0-l) + (w/2)
            double leftInWorld = (0.0d - this.picBoxSource.Left) + ((double)this.palSource.Width / 2);
            double topInWorld = (0.0d - this.picBoxSource.Top) + ((double)this.palSource.Height / 2);
            // 位置变化值
            double leftPlus = leftInWorld / this.picBoxSource.Width * divWidth;
            double topPlus = topInWorld / this.picBoxSource.Height * divHeight;
            // 更新尺寸
            this.picBoxSource.Width = (int)((double)this.picBoxSource.Width - divWidth);
            this.picBoxSource.Height = (int)((double)this.picBoxSource.Height - divHeight);
            // 更新位置
            this.picBoxSource.Left = (int)((double)this.picBoxSource.Left + leftPlus);
            this.picBoxSource.Top = (int)((double)this.picBoxSource.Top + topPlus);
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
        }

        /// <summary>
        /// 自动播放按钮
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnAuto_Click(object sender, EventArgs e)
        {
            // 如果是自动播放中
            if (this.isAuto)
            {
                // 设置按钮背景色图片 为  蓝色
                this.btnAuto.BackgroundImage = Properties.Resources.menu_hover;
                // 停止自动播放
                this.timerAuto.Stop();
                // 设置标志为停止自动播放
                this.isAuto = false;
            }
            else
            {
                // 设置按钮背景色图片 为  绿色
                this.btnAuto.BackgroundImage = Properties.Resources.menu_visited;
                // 如果已经播放过
                if (this.autoPosIndustry != -1)
                {
                    // 切换到上次播放的位置
                    // 点击行业按钮
                    this.btn_Industry_Click(((Button)this.lstBtnIndustry[this.autoPosIndustry]), null);
                }
                // 首次执行
                this.timerAuto_Tick(null, null);
                // 开始自动播放
                this.timerAuto.Start();
                // 设置标志为自动播放
                this.isAuto = true;
            }
        }

        /// <summary>
        /// timer任务
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void timerAuto_Tick(object sender, EventArgs e)
        {
            /// 行业  按钮  ///
            if (this.isNext)
            {
                // 未播放过
                if (this.autoPosIndustry == -1)
                {
                    this.autoPosIndustry = 0;
                }
                else
                {
                    // +1
                    this.autoPosIndustry++;
                    if (this.autoPosIndustry >= this.lstBtnIndustry.Count)
                    {
                        this.autoPosIndustry = 0;
                    }
                }
                // 点击行业按钮
                this.btn_Industry_Click(((Button)this.lstBtnIndustry[this.autoPosIndustry]), null);
                // 不自动进入下一行业
                this.isNext = false;
                // 重新选择  技术 -1
                this.autoPosTech = -1;
            }

            /// 技术  按钮  ///
            //如果-1，找第一个
            if (-1 == this.autoPosTech)
            {
                int iIndex = 0;
                for ( iIndex = 0; iIndex < this.lstBtnTech.Count; iIndex++ )
                {
                    if ( true == ((Button)this.lstBtnTech[iIndex]).Enabled  )
                    {
                        // 找到了，执行
                        this.autoPosTech = iIndex;
                        this.btn_Technology_Click(((Button)this.lstBtnTech[this.autoPosTech]), null);
                        break;
                    }
                }
                //如果没找到, 进入下一行业
                if (iIndex == this.lstBtnTech.Count)
                {
                    //设置进入下一行业
                    this.isNext = true;
                    this.timerAuto_Tick(null, null);
                }
            }
            // 如果不是-1
            else
            {                
                int iIndex = 0;
                if (this.autoPosTech == this.lstBtnTech.Count)
                {
                    //设置进入下一行业
                    this.isNext = true;
                    this.timerAuto_Tick(null, null);
                }
                for ( iIndex = this.autoPosTech + 1; iIndex < this.lstBtnTech.Count; iIndex++ )
                {
                    if (true == ((Button)this.lstBtnTech[iIndex]).Enabled)
                    {
                        // 找到了，执行
                        this.autoPosTech = iIndex;
                        this.btn_Technology_Click(((Button)this.lstBtnTech[this.autoPosTech]), null);
                        break;
                    }
                }
                //如果没找到, 进入下一行业
                if (iIndex == this.lstBtnTech.Count)
                {
                    //设置进入下一行业
                    this.isNext = true;
                    this.timerAuto_Tick(null, null);
                }
            }
        }

        /// <summary>
        /// flash播放控制按钮
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void btnPlay_Click(object sender, EventArgs e)
        {
            // 如果是flash播放中
            if (this.isFlashPlay)
            {
                // 设置按钮背景色图片 为  >>
                this.btnPlay.BackgroundImage = Properties.Resources.icon_play;//  >>
                // 停止自动播放
                this.flashPlayer.Stop();
                // 设置标志为停止自动播放
                this.isFlashPlay = false;
            }
            else
            {
                // 设置按钮背景色图片 为  ||
                this.btnPlay.BackgroundImage = Properties.Resources.icon_pause;  //  ||
                // 开始自动播放
                this.flashPlayer.Play();
                // 设置标志为自动播放
                this.isFlashPlay = true;
            }
        }

        /// <summary>
        /// timerHover任务
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void timerHover_Tick(object sender, EventArgs e)
        {
            this.move(this.pointHover);
        }

        /// <summary>
        /// 鼠标落下
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void picMove_MouseDown(object sender, MouseEventArgs e)
        {
            this.move(e.Location);
            this.pointHover = e.Location;
            this.isDownInPicResources = true;
            // 启动timer
            this.timerHover.Start();
        }

        /// <summary>
        /// 鼠标移动
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void picMove_MouseMove(object sender, MouseEventArgs e)
        {
            // 更新位置
            this.pointHover = e.Location;
        }

        /// <summary>
        /// 鼠标抬起
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void picMove_MouseUp(object sender, MouseEventArgs e)
        {
            this.isDownInPicResources = false;
            // 停止 移动 计时器
            this.timerHover.Stop();
        }

        /// <summary>
        /// 按键出发的移动
        /// </summary>
        /// <param name="point"></param>
        private void move(Point point)
        {
            // 设置按钮 可点
            if (Common.BTN_UNABLE == this.btnReset.Tag.ToString())
            {
                this.btnReset.Image = Properties.Resources.icon_reset_available;
                this.btnReset.Tag = Common.BTN_ENABLE;
            }
            // 上
            if (this.rectTop.Contains(point))
            {
                if (this.picBoxSource.Height > this.palSource.Height)
                {
                    // 移动画布的n/10 Common.moveRate
                    this.picBoxSource.Top -= this.palSource.Height / Common.moveRate;
                }
                else
                {
                    // 移动整张图的n/10 Common.moveRate
                    this.picBoxSource.Top -= this.picBoxSource.Height / Common.moveRate;
                }
                return;
            }
            // 下
            if (this.rectBottom.Contains(point))
            {
                if (this.picBoxSource.Height > this.palSource.Height)
                {
                    this.picBoxSource.Top += this.palSource.Height / Common.moveRate;
                }
                else
                {
                    this.picBoxSource.Top += this.picBoxSource.Height / Common.moveRate;
                }
                return;
            }
            // 左
            if (this.rectLeft.Contains(point))
            {
                if (this.picBoxSource.Width > this.palSource.Width)
                {
                    this.picBoxSource.Left -= this.palSource.Width / Common.moveRate;
                }
                else
                {
                    this.picBoxSource.Left -= this.picBoxSource.Width / Common.moveRate;
                }
                return;
            }
            // 右
            if (this.rectRight.Contains(point))
            {
                if (this.picBoxSource.Width > this.palSource.Width)
                {
                    this.picBoxSource.Left += this.palSource.Width / Common.moveRate;
                }
                else
                {
                    this.picBoxSource.Left += this.picBoxSource.Width / Common.moveRate;
                }
                return;
            }
            this.timerHover.Stop();
        }

        private void panSet_MouseClick(object sender, MouseEventArgs e)
        {
            FormSetting frmSetting = new FormSetting();
            if (DialogResult.OK == frmSetting.ShowDialog())
            {
                // 读取配置文件信息
                this.readConfig();
            }
        }

        //IDL初始化
        private void IDLDrawWidgetCreate()
        {
            int n;
            //初始化
            n = axIDLDrawWidget1.InitIDL((int)this.Handle);
            if (n == 0)
            {
                MessageBox.Show("IDL初始化失败", "IDL初始化失败，无法继续！");
                return;
            }
            //对象法程序显示
            axIDLDrawWidget1.GraphicsLevel = 2;
            //编译源码文件
            axIDLDrawWidget1.ExecuteStr(".compile 'Satellite_demo.pro'");
            //axIDLDrawWidget1.OnExpose = "if Obj_Valid(oProj) eq 1 then oProj.Draw";
            //初始化界面
            axIDLDrawWidget1.CreateDrawWidget();

        }

        private void picWX_Click(object sender, EventArgs e)
        {

            this.IDLDrawWidgetCreate();

            axIDLDrawWidget1.ExecuteStr("SATELLITE_DEMO," + axIDLDrawWidget1.DrawId.ToString());
            this.lblDetial.Visible = false;
            this.lblTitle.Visible = false;
            this.picBoxSource.Visible = false;
            this.btnZoomOut.Visible = false;
            this.btnZoomIn.Visible = false;
            this.btnReset.Visible = false;
            this.picMove.Visible = false;  
        }

        

        

       


    }
}
