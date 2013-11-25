using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace dongwangDemo
{
    static class Program
    {
        // <summary>
        // 应用程序的主入口点。这里是我修改的地方，我要提交到Github
        // </summary>
        [STAThread]
        static void Main()
        {
            string strAppPath = "";
            strAppPath = AppDomain.CurrentDomain.SetupInformation.ApplicationBase;
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            Common.strAppPath = strAppPath;

            //欢饮画面
            //FormWelcome fW = new FormWelcome();
            //fW.ShowDialog();

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new FormMain());
        }
    }
}
