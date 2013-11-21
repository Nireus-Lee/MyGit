using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.IO;
using System.Drawing;
using System.Windows.Forms;

namespace dongwangDemo
{
    public static class Common
    {
        /**/
        ///  声明读写INI文件的API函数
        [DllImport("kernel32")]
        private static extern long WritePrivateProfileString(string section, string key, string val, string filePath);

        [DllImport("kernel32")]
        private static extern int GetPrivateProfileString(string section, string key, string def, StringBuilder retVal, int size, string filePath);

        /// 声明改变样式API函数
        [System.Runtime.InteropServices.DllImport("user32.dll ")]
        public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int wndproc);
        [System.Runtime.InteropServices.DllImport("user32.dll ")]
        public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

        #region 常量
        public const string READ_INI_ERROR = "read_ini_error";
        public const string INDEX_1 = "1";
        public const string INDEX_2 = "2";
        public const string INDEX_3 = "3";
        public const string INDEX_4 = "4";
        public const string INDEX_5 = "5";
        public const string INDEX_6 = "6";
        public const string INDEX_7 = "7";
        public const string INDEX_8 = "8";
        public const string INDEX_9 = "9";
        public const string INDEX_10 = "10";
        // Config.ini
        public const string INI_CONFIG_PATH = "Ini\\Config.ini";
        // 技术按钮数量
        public const int TEC_BTN_COUNT = 6;
        // 按钮状态INI_KEY
        public const string INI_KEY_BTN_STATUS = "BtnStatus";
        // 按钮可用
        public const string BTN_ENABLE = "1";
        // 按钮不可用
        public const string BTN_UNABLE = "0";
        // 内容提要INT_KEY
        public const string INI_KEY_SUMMARY_PATH = "SummaryPath";
        // 图片INT_KEY
        public const string INI_KEY_PICTURE_PATH = "PicturePath";
        // 文档INT_KEY
        public const string INI_KEY_DOCUMENT_PATH = "DocumentPath";

        // 技术按钮颜色值
        public static Color COL_BTN_TEC_NORMAL = Color.FromArgb(56, 171, 255);
        public static Color COL_BTN_TEC_SELECT = Color.FromArgb(37, 189, 26);
        public static Color COL_BTN_TEC_UNABLE = Color.FromArgb(204, 204, 204);

        // 生成报告按钮颜色值
        public static Color COL_BTN_REC_NORMAL = Color.FromArgb(255, 102, 0);
        public static Color COL_BTN_REC_UNABLE = Color.FromArgb(204, 204, 204);

        public const int GWL_STYLE = -16;
        public const int WS_DISABLED = 0x8000000;

        // 缩放增量KEY
        public const string INI_KEY_ZOOM_RATE = "ZoomRate";
        // 自动播放频率
        public const string INI_KEY_AUTO_RATE = "AutoRate";
        // 移动百分比频率
        public const string INI_KEY_MOVE_RATE = "MoveRate";

        #endregion

        #region 公共变量
        // 应用程序路径
        public static string strAppPath = "";
        public static int zoomRate = 20;
        public static int autoRate = 20 * 1000;
        public static int moveRate = 3;
        #endregion


        #region 读写INI
        ///  <summary>
        ///  写INI文件
        ///  </summary>
        ///  <param  name="Section">Section</param>
        ///  <param  name="Key">Key</param>
        ///  <param  name="value">value</param>
        public static void WriteIniValue(string Section, string Key, string value, string strPath)
        {
            WritePrivateProfileString(Section, Key, value, strPath);
        }

        ///  <summary>
        ///  读取INI文件指定部分
        ///  </summary>
        ///  <param  name="Section">Section</param>
        ///  <param  name="Key">Key</param>
        ///  <returns>String</returns>  
        public static string ReadIniValue(string Section, string Key, string strPath)
        {
            StringBuilder temp = new StringBuilder(1024);
            int i = GetPrivateProfileString(Section, Key, Common.READ_INI_ERROR, temp, 1024, strPath);
            return temp.ToString();
        }
        #endregion

        #region 读TXT文件
        public static string[] ReadTxtFile(string strPath)
        {
            if (null == strPath || "" == strPath)
            {
                return null;
            }

            if (!File.Exists(strPath))
            {
                return null;
            }

            StreamReader sm = null;
            try
            {
                //Encoding fileEncoding = Common.GetEncoding(strPath, Encoding.GetEncoding("GB2312"));
                sm = new StreamReader(strPath, Encoding.GetEncoding("GB2312"));//用该编码创建StreamReader
                string strTitle = sm.ReadLine();
                string strDetail = sm.ReadToEnd();

                string[] ArrayInfo = new string[] { strTitle, strDetail};
                return ArrayInfo;
            }
            catch (IOException e)
            {
                Console.WriteLine(e.ToString());
                return null;
            }
            finally
            {
                try
                {
                    sm.Close();
                }
                catch (IOException exc)
                {
                    Console.WriteLine(exc.ToString());
                }
            }
        }

        // <summary>
        /// 取得一个文本文件的编码方式。
        /// </summary>
        /// <param name="fileName">文件名。</param>
        /// <param name="defaultEncoding">默认编码方式。当该方法无法从文件的头部取得有效的前导符时，将返回该编码方式。< /param>
        /// <returns></returns>
        public static Encoding GetEncoding(string fileName, Encoding defaultEncoding)
        {

            FileStream fs = new FileStream(fileName, FileMode.Open);

            Encoding targetEncoding = GetEncoding(fs, defaultEncoding);

            fs.Close();

            return targetEncoding;

        }

        /// <summary>
　　　　/// 取得一个文本文件流的编码方式。
　　　　/// </summary>
　　　　/// <param name="stream">文本文件流。</param>
　　　　/// <param name="defaultEncoding">默认编码方式。当该方法无法从文件的头部取得有效的前导符时，将返回该编码方式。< /param>
　　　　/// <returns></returns>
        public static Encoding GetEncoding(FileStream stream, Encoding defaultEncoding)
        {
            Encoding targetEncoding = defaultEncoding;
            if (stream != null && stream.Length >= 2)
            {
                //保存文件流的前4个字节
                byte byte1 = 0;
                byte byte2 = 0;
                byte byte3 = 0;
                byte byte4 = 0;
                //保存当前Seek位置
                long origPos = stream.Seek(0, SeekOrigin.Begin);
                stream.Seek(0, SeekOrigin.Begin);
                int nByte = stream.ReadByte();
                byte1 = Convert.ToByte(nByte);
                byte2 = Convert.ToByte(stream.ReadByte());
                if (stream.Length >= 3)
                {
                    byte3 = Convert.ToByte(stream.ReadByte());
                }
                if (stream.Length >= 4)
                {
                    byte4 = Convert.ToByte(stream.ReadByte());
                }
                //根据文件流的前4个字节判断Encoding
                //Unicode {0xFF, 0xFE};
                //BE-Unicode {0xFE, 0xFF};
                //UTF8 = {0xEF, 0xBB, 0xBF};
                if (byte1 == 0xFE && byte2 == 0xFF)//UnicodeBe        
                {
                    targetEncoding = Encoding.BigEndianUnicode;
                }
                if (byte1 == 0xFF && byte2 == 0xFE && byte3 != 0xFF)//Unicode     
                {
                    targetEncoding = Encoding.Unicode;
                }
                if (byte1 == 0xEF && byte2 == 0xBB && byte3 == 0xBF)//UTF8
                {
                    targetEncoding = Encoding.UTF8;
                }
                //恢复Seek位置
                stream.Seek(origPos, SeekOrigin.Begin);
            }
            return targetEncoding;
        }

        #endregion

        #region 控制按钮颜色
        /// <summary>
        /// 控制按钮颜色     
        /// </summary>
        /// <param name="c"></param>
        /// <param name="enabled"></param>
        public static void SetControlEnabled(Control c, bool enabled)
        {
            if (enabled)
            { SetWindowLong(c.Handle, GWL_STYLE, (~WS_DISABLED) & GetWindowLong(c.Handle, GWL_STYLE)); }
            else
            { SetWindowLong(c.Handle, GWL_STYLE, WS_DISABLED + GetWindowLong(c.Handle, GWL_STYLE)); }
        }
        #endregion


    }
}
