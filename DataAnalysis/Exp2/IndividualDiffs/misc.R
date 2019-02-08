EF_slout <- merge(slout_acc_stand, EF, by.x = "Subject", by.y = "subnum")

all <- merge(EF_slout, nd_standard, by.x = "Subject", by.y = "Subject")

cor.test(EF_slout$incong_rt_cost, EF_slout$acc_z)

m1 <- lmer(acc_z ~ System + incong_rt_cost + switch_eff_time + m_time_to_first + nd_ss  + (1|Subject), data = all)