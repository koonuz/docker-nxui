#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

PATH_FOR_GEO_IP='/usr/local/x-ui/bin/geoip.dat'
PATH_FOR_GEO_SITE='/usr/local/x-ui/bin/geosite.dat'
URL_FOR_GEO_IP='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat'
URL_FOR_GEO_SITE='https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat'

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [默认$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "是否重启【x-ui面板】？重启【x-ui面板】也会一并重启【xray服务】" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}按回车返回主菜单: ${plain}" && read temp
    show_menu
}

reset_user() {
    confirm "确定要将用户名和密码重置为 admin 吗？" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "用户名和密码已重置为 ${green}admin${plain}，现在请重启【x-ui面板】"
    confirm_restart
}

reset_config() {
    confirm "确定要重置所有关于【x-ui面板】的设置吗？账号数据不会丢失，用户名和密码不会改变" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "所有关于【x-ui面板】的设置已重置为默认值，现在请重启【x-ui面板】，并使用默认的 ${green}54321${plain} 端口进行访问"
    confirm_restart
}

check_config() {
    info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        echo -n "无法获取当前关于【x-ui面板】的设置，请检查日志"
        show_menu
    fi
    echo -e "${info}"
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${yellow}【x-ui面板】与【xray服务】已运行，无需再次启动!如需重启x-ui进程，请选择重启!${plain}"
    else
        sv start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}【x-ui面板】与【xray服务】启动成功!${plain}"
        else
            echo -e "${red}启动失败，可能是因为启动时间超过了两秒，请稍后查看日志信息${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        echo -e "${yellow}【x-ui面板】与【xray服务】已停止运行，无需再次停止!${plain}"
    else
        sv stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            echo -e "${green} 【x-ui面板】与【xray服务】停止成功!${plain}"
        else
            echo -e "${red}停止失败，可能是因为停止时间超过了两秒，请稍后查看日志信息${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    sv restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}【x-ui面板】与【xray服务】重启成功!${plain}"
    else
        echo -e "${red}重启失败，可能是因为启动时间超过了两秒，请稍后查看日志信息${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

check_status() {
    temp=$(sv status x-ui | awk '{print $1}' | cut -d ":" -f1)
    if [[ x"${temp}" == x"run" ]]; then
        return 0
    else
        return 1
    fi
}

show_status() {
    check_status
    case $? in
    0)
        echo -e "【x-ui面板】与【xray服务】状态: ${green}已运行${plain}"
        ;;
    1)
        echo -e "【x-ui面板】与【xray服务】状态: ${red}未运行${plain}"
        ;;
    esac
    before_show_menu
}

set_port() {
    echo && echo -n -e "输入端口号[1-65535]: " && read port
    if [[ -z "${port}" ]]; then
        echo -e "${yellow}已取消${plain}"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e "设置端口完毕，现在请重启面板，并使用新设置的端口 ${green}${port}${plain} 访问面板"
        confirm_restart
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui
    before_show_menu
}

#add for cron jobs,including sync geo data,check logs and restart x-ui
cron_jobs() {
    clear
    echo -e "
  ${green}定时任务管理${plain}
  ${green}0.${plain}  返回主菜单
  ${green}1.${plain}  开启自动更新geo数据
  ${green}2.${plain}  关闭自动更新geo数据
  "
    echo && read -p "请输入选择 [0-4]: " num
    case "${num}" in
    0)
        show_menu
        ;;
    1)
        enable_auto_update_geo
        ;;
    2)
        disable_auto_update_geo
        ;;
    *)
        LOGE "请输入正确的数字 [0-2]"
        ;;
    esac
}

#update geo data
update_geo() {
    #back up first
    mv ${PATH_FOR_GEO_IP} ${PATH_FOR_GEO_IP}.bak
    #update data
    curl -s -L -o ${PATH_FOR_GEO_IP} ${URL_FOR_GEO_IP}
    if [[ $? -ne 0 ]]; then
        echo -e "geoip.dat ${red}更新失败${plain}"
        mv ${PATH_FOR_GEO_IP}.bak ${PATH_FOR_GEO_IP}
    else
        echo -e "geoip.dat ${green}更新成功${plain}"
        rm -f ${PATH_FOR_GEO_IP}.bak
    fi
    mv ${PATH_FOR_GEO_SITE} ${PATH_FOR_GEO_SITE}.bak
    curl -s -L -o ${PATH_FOR_GEO_SITE} ${URL_FOR_GEO_SITE}
    if [[ $? -ne 0 ]]; then
        echo -e "geosite.dat ${red}更新失败${plain}"
        mv ${PATH_FOR_GEO_SITE}.bak ${PATH_FOR_GEO_SITE}
    else
        echo "geosite.dat ${green}更新成功${plain}"
        rm -f ${PATH_FOR_GEO_SITE}.bak
    fi
    #restart x-ui
    sv restart x-ui
}

enable_auto_update_geo() {
    echo -e "${yellow}正在开启geo数据自动更新...${plain}"
    crontab -l >/tmp/crontabTask.tmp
    echo "00 4 */2 * * x-ui geo > /dev/null" >>/tmp/crontabTask.tmp
    crontab /tmp/crontabTask.tmp
    rm /tmp/crontabTask.tmp
    echo -e "${green}geo数据自动更新开启成功${plain}"
}

disable_auto_update_geo() {
    crontab -l | grep -v "x-ui geo" | crontab -
    if [[ $? -ne 0 ]]; then
        echo -e "${red}关闭geo数据自动更新失败${plain}"
    else
        echo -e "${green}关闭geo数据自动更新成功${plain}"
    fi
}

show_menu() {
    echo -e "
  ${green}x-ui 面板管理脚本${plain}
--- 该版本为 FranzKafkaYu 增强版 ---  
- https://github.com/FranzKafkaYu/x-ui -
  ${green}0.${plain} 退出脚本
————————————————
  ${green}1.${plain} 重置【x-ui面板】用户名和密码
  ${green}2.${plain} 重置【x-ui面板】所有设置
  ${green}3.${plain} 设置【x-ui面板】访问端口
  ${green}4.${plain} 查看当前【x-ui面板】所有设置
————————————————
  ${green}5.${plain} 启动【x-ui面板】与【xray服务】进程
  ${green}6.${plain} 停止【x-ui面板】与【xray服务】进程
  ${green}7.${plain} 重启【x-ui面板】与【xray服务】进程
  ${green}8.${plain} 查看【x-ui面板】与【xray服务】状态
————————————————
  ${green}9.${plain} 配置x-ui定时任务
  ${green}10.${plain} 迁移 v2-ui 账号数据至 x-ui"
    echo && read -p "请输入选择 [0-10]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) reset_user
        ;;
        2) reset_config
        ;;
        3) set_port
        ;;
        4) check_config
        ;;
        5) start
        ;;
        6) stop
        ;;
        7) restart
        ;;
        8) show_status
        ;;
        9) cron_jobs
        ;;
        10) migrate_v2_ui
        ;;
        *) echo -e "${red}请输入正确的数字 [0-10]${plain}"
        ;;
    esac
}
show_menu
