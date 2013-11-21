using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace dongwangDemo
{
    public partial class FormSetting : Form
    {
        public FormSetting()
        {
            InitializeComponent();
        }

        private void FormSetting_Load(object sender, EventArgs e)
        {
            string ret = null;
            // 缩放率
            ret = Common.ReadIniValue("Config", Common.INI_KEY_ZOOM_RATE, Common.strAppPath + Common.INI_CONFIG_PATH);
            this.txtZoom.Text = ret;

            // 自动播放频率
            ret = Common.ReadIniValue("Config", Common.INI_KEY_AUTO_RATE, Common.strAppPath + Common.INI_CONFIG_PATH);
            this.txtPlay.Text = ret;
           
            // 自动播放频率
            ret = Common.ReadIniValue("Config", Common.INI_KEY_MOVE_RATE, Common.strAppPath + Common.INI_CONFIG_PATH);
            this.txtMove.Text = ret;
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            Common.WriteIniValue("Config", Common.INI_KEY_ZOOM_RATE, this.txtZoom.Text.Trim(), Common.strAppPath + Common.INI_CONFIG_PATH);
            Common.WriteIniValue("Config", Common.INI_KEY_AUTO_RATE, this.txtPlay.Text.Trim(), Common.strAppPath + Common.INI_CONFIG_PATH);
            Common.WriteIniValue("Config", Common.INI_KEY_MOVE_RATE, this.txtMove.Text.Trim(), Common.strAppPath + Common.INI_CONFIG_PATH);

            this.DialogResult = DialogResult.OK;
        }

        private void btnQuit_Click(object sender, EventArgs e)
        {
            this.DialogResult = DialogResult.Cancel;
        }

        
    }
}
