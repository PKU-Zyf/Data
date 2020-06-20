global path = "Enter your path here."
import excel "$path\data.xlsx", sheet("Sheet1") firstrow


// 因变量
gen level = 3 * NPV_law + 2 * NPV_leg + NPV_com    // 评价NPV支持程度


// 自变量
gen red_p_2016 = (abs(r_p_2016 - d_p_2016) / (r_p_2016 - d_p_2016) + 1) / 2    // 在2016大选中的结果，红州为1，蓝州为0
gen blue_win_2016 = d_p_2016 - r_p_2016    // 计算具体得票之差，民主党比共和党多了多少
gen blue_p_2016 = 1 - red_p_2016    // 在2016大选中的结果，红州为0，蓝州为1，留着后面做交互项分析时用
gen swing_p = 0 if red_p_2016 == red_p_2012 & red_p_2012 == red_p_2008 & red_p_2008 == red_p_2004
replace swing_p = 1 if swing_p != 0
gen red_s_2020 = (abs(r_s_2020 - d_s_2020) / (r_s_2020 - d_s_2020) + 1) / 2    // 2020州参议院组成，红州为1，蓝州为0
gen red_h_2020 = (abs(r_h_2020 - d_h_2020) / (r_h_2020 - d_h_2020) + 1) / 2    // 2020州众议院组成，红州为1，蓝州为0
gen red_l_2020 = 1 if red_s_2020 == 1 & red_h_2020 == 1    // 定义议会红州
replace red_l_2020 = 0 if red_s_2020 == 0 | red_h_2020 == 0
replace red_l_2020 = 1 if abrv == "NE"    // 针对内布拉斯加州只有一院的特殊情况
gen blue_l_2020 = 1 if red_s_2020 == 0 & red_h_2020 == 0    // 定义议会蓝州
replace blue_l_2020 = 0 if red_s_2020 == 1 | red_h_2020 == 1
gen switch_l = 1 if s_switch >= 2005 | h_switch >= 2005    // NPV出现之后议会党派势力有过摇摆的州
replace switch_l = 0 if s_switch < 2005 & h_switch < 2005
replace switch_l = . if abrv == "DC"    // 针对DC没有议院的特殊情况


// 检验相关性
pwcorr level blue_p_2016 blue_win_2016 blue_l_2020, sig
pwcorr level swing_p switch_l, sig


// 回归分析1：不含交互项的模型
eststo: reg level blue_p_2016
eststo: reg level blue_win_2016    // 表现最差
eststo: reg level blue_l_2020

eststo: reg level blue_l_2020 swing_p    // 都不显著
eststo: reg level blue_l_2020 switch_l
eststo: reg level blue_p_2016 switch_l
eststo: reg level blue_p_2016 swing_p


// 输出回归分析1的表格
esttab using "$path\result_1.csv", b(%9.3fc) se(%9.3fc) star(* 0.10 ** 0.05 *** 0.01) nogaps compress ar2 obslast
eststo clear


// 回归分析2：含交互项的模型
gen blue_pxswing_p = blue_p_2016 * swing_p
gen blue_lxswitch_l = blue_l_2020 * switch_l
gen blue_pxswitch_l = blue_p_2016 * switch_l
gen blue_lxswing_p = blue_l_2020 * swing_p
gen blue_winxswing_p = blue_win_2016 * swing_p

eststo: reg level blue_p_2016
eststo: reg level blue_p_2016 swing_p blue_lxswitch_l blue_winxswing_p
eststo: reg level blue_p_2016 switch_l blue_pxswitch_l blue_pxswing_p
eststo: reg level blue_p_2016 swing_p blue_pxswitch_l blue_winxswing_p
eststo: reg level blue_p_2016 switch_l blue_pxswitch_l blue_winxswing_p    // 最优秀的模型


// 输出回归分析2的表格
esttab using "$path\result_2.csv", b(%9.3fc) se(%9.3fc) star(* 0.10 ** 0.05 *** 0.01) nogaps compress ar2 obslast
eststo clear

