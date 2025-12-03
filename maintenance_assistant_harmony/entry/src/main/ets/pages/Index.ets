import { HomeViewModel } from '../viewmodel/HomeViewModel';
import { Plan } from '../model/PlanModel';
import { Habit } from '../model/HabitModel';
import { Anchor } from '../model/AnchorModel';
import { AppColors, AppDimens, AppStrings } from '../common/Constants';
import { ImmersiveBackground } from '../components/ImmersiveBackground';
import { PlanCard } from '../components/PlanCard';
import { HabitCard } from '../components/HabitCard';
import { AnchorCard } from '../components/AnchorCard';
import { EmptyState } from '../components/EmptyState';
import { AddModal } from '../components/AddModal';
import { AddAnchorModal } from '../components/AddAnchorModal';
import { SuccessPopup } from '../components/SuccessPopup';
import { AppDrawer } from '../components/AppDrawer';
import { SettingSheet } from '../components/SettingSheet';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct Index {
  @State viewModel: HomeViewModel = new HomeViewModel();
  @State currentView: string = 'plans';
  @State expandedCardId: string = '';
  @State showDrawer: boolean = false;
  @State showSuccessPopup: boolean = false;
  @State successDescription: string = '';
  @State successType: string = 'action';

  // 弹窗控制器
  private addModalController: CustomDialogController | null = null;
  private addAnchorModalController: CustomDialogController | null = null;
  private successPopupController: CustomDialogController | null = null;
  private settingSheetController: CustomDialogController | null = null;

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.viewModel.init(context);
  }

  build() {
    Stack() {
      // 背景
      ImmersiveBackground()

      // 主内容
      Column() {
        // 头部
        this.Header()

        // 内容区域
        Scroll() {
          Column() {
            if (this.currentView === 'plans') {
              this.PlansView()
            } else if (this.currentView === 'habits') {
              this.HabitsView()
            } else {
              this.AnchorsView()
            }
          }
          .width('100%')
          .padding({ bottom: 120 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')

      // 底部视图切换器
      this.ViewSwitcher()

      // FAB 按钮
      this.FAB()

      // 侧边栏
      if (this.showDrawer) {
        this.DrawerOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  Header() {
    Row() {
      // 菜单按钮
      Column() {
        Image($r('sys.media.ohos_ic_public_drawer'))
          .width(AppDimens.ICON_LARGE)
          .height(AppDimens.ICON_LARGE)
          .fillColor(AppColors.TEXT_PRIMARY)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(255, 255, 255, 0.8)')
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.showDrawer = true;
      })

      // 标题
      Text(AppStrings.APP_NAME)
        .fontSize(AppDimens.FONT_HERO)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ left: 16 })

      Blank()

      // 通知按钮
      Column() {
        Image($r('sys.media.ohos_ic_public_ring'))
          .width(AppDimens.ICON_LARGE)
          .height(AppDimens.ICON_LARGE)
          .fillColor(AppColors.PRIMARY)
      }
      .width(40)
      .height(40)
      .backgroundColor('rgba(255, 255, 255, 0.8)')
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 16 })
  }

  @Builder
  PlansView() {
    Column() {
      // 进行中的计划
      if (this.viewModel.ongoingPlans.length > 0) {
        ForEach(this.viewModel.ongoingPlans, (plan: Plan) => {
          PlanCard({
            plan: plan,
            isExpanded: this.expandedCardId === plan.id,
            onTap: () => {
              this.expandedCardId = this.expandedCardId === plan.id ? '' : plan.id;
            },
            onToggleStatus: () => {
              this.viewModel.togglePlanStatus(plan.id);
              if (plan.status !== AppStrings.STATUS_COMPLETED) {
                this.triggerSuccess(plan.name, 'dream');
              }
            },
            onDelete: () => this.viewModel.deletePlan(plan.id),
            onPin: () => this.viewModel.pinPlan(plan.id),
            onEdit: () => this.showEditPlanModal(plan),
            onDetail: () => {}
          })
            .margin({ bottom: 12 })
        }, (plan: Plan) => plan.id)
      } else {
        EmptyState({
          icon: AppStrings.EMPTY_PLANS_ICON,
          title: AppStrings.EMPTY_PLANS_TITLE,
          subtitle: AppStrings.EMPTY_PLANS_SUBTITLE
        })
      }

      // 已完成的计划
      if (this.viewModel.completedPlans.length > 0) {
        Row() {
          Text('已完成')
            .fontSize(AppDimens.FONT_XLARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)

          Column() {
            Text(`${this.viewModel.completedPlans.length}`)
              .fontSize(AppDimens.FONT_SMALL)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(AppColors.PRIMARY)
          .borderRadius(12)
          .margin({ left: 8 })
        }
        .width('100%')
        .margin({ top: 32, bottom: 16 })

        ForEach(this.viewModel.completedPlans, (plan: Plan) => {
          PlanCard({
            plan: plan,
            isExpanded: this.expandedCardId === plan.id,
            onTap: () => {
              this.expandedCardId = this.expandedCardId === plan.id ? '' : plan.id;
            },
            onToggleStatus: () => this.viewModel.togglePlanStatus(plan.id),
            onDelete: () => this.viewModel.deletePlan(plan.id),
            onPin: () => this.viewModel.pinPlan(plan.id),
            onEdit: () => {},
            onDetail: () => {}
          })
            .margin({ bottom: 12 })
        }, (plan: Plan) => plan.id)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20 })
  }

  @Builder
  HabitsView() {
    Column() {
      // 进行中的习惯
      if (this.viewModel.activeHabits.length > 0) {
        ForEach(this.viewModel.activeHabits, (habit: Habit) => {
          HabitCard({
            habit: habit,
            isExpanded: this.expandedCardId === habit.id,
            onTap: () => {
              this.expandedCardId = this.expandedCardId === habit.id ? '' : habit.id;
            },
            onCheck: () => {
              this.viewModel.checkHabit(habit.id);
              this.triggerSuccess(habit.name, 'action');
            },
            onToggleStatus: () => this.viewModel.toggleHabitStatus(habit.id),
            onDelete: () => this.viewModel.deleteHabit(habit.id),
            onPin: () => this.viewModel.pinHabit(habit.id),
            onEdit: () => this.showEditHabitModal(habit),
            onDetail: () => {}
          })
            .margin({ bottom: 12 })
        }, (habit: Habit) => habit.id)
      } else {
        EmptyState({
          icon: AppStrings.EMPTY_HABITS_ICON,
          title: AppStrings.EMPTY_HABITS_TITLE,
          subtitle: AppStrings.EMPTY_HABITS_SUBTITLE
        })
      }

      // 已停用的习惯
      if (this.viewModel.stoppedHabits.length > 0) {
        Text('已停用')
          .fontSize(AppDimens.FONT_XLARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
          .margin({ top: 32, bottom: 16 })

        ForEach(this.viewModel.stoppedHabits, (habit: Habit) => {
          HabitCard({
            habit: habit,
            isExpanded: this.expandedCardId === habit.id,
            onTap: () => {
              this.expandedCardId = this.expandedCardId === habit.id ? '' : habit.id;
            },
            onCheck: () => {},
            onToggleStatus: () => this.viewModel.toggleHabitStatus(habit.id),
            onDelete: () => this.viewModel.deleteHabit(habit.id),
            onPin: () => this.viewModel.pinHabit(habit.id),
            onEdit: () => this.showEditHabitModal(habit),
            onDetail: () => {}
          })
            .margin({ bottom: 12 })
        }, (habit: Habit) => habit.id)
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20 })
  }

  @Builder
  AnchorsView() {
    Column() {
      if (this.viewModel.anchors.length > 0) {
        ForEach(this.viewModel.anchors, (anchor: Anchor) => {
          AnchorCard({
            anchor: anchor,
            onTap: () => {},
            onEdit: () => this.showEditAnchorModal(anchor),
            onDelete: () => this.viewModel.deleteAnchor(anchor.id)
          })
        }, (anchor: Anchor) => anchor.id)
      } else {
        EmptyState({
          icon: AppStrings.EMPTY_ANCHORS_ICON,
          title: AppStrings.EMPTY_ANCHORS_TITLE,
          subtitle: AppStrings.EMPTY_ANCHORS_SUBTITLE
        })
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20 })
  }

  @Builder
  ViewSwitcher() {
    Row() {
      this.SwitchButton(AppStrings.TAB_PLANS, 'plans')
      this.SwitchButton(AppStrings.TAB_HABITS, 'habits')
      this.SwitchButton(AppStrings.TAB_ANCHORS, 'anchors')
    }
    .padding(4)
    .backgroundColor('rgba(255, 255, 255, 0.9)')
    .borderRadius(16)
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 4
    })
    .position({ x: 24, y: '90%' })
  }

  @Builder
  SwitchButton(text: string, view: string) {
    Text(text)
      .fontSize(AppDimens.FONT_MEDIUM)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.currentView === view ? Color.White : AppColors.TEXT_SECONDARY)
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .backgroundColor(this.currentView === view ? AppColors.PRIMARY : Color.Transparent)
      .borderRadius(12)
      .animation({ duration: 300 })
      .onClick(() => {
        this.currentView = view;
        this.expandedCardId = '';
      })
  }

  @Builder
  FAB() {
    Column() {
      Image($r('sys.media.ohos_ic_public_add'))
        .width(AppDimens.ICON_XLARGE)
        .height(AppDimens.ICON_XLARGE)
        .fillColor(Color.White)
    }
    .width(AppDimens.FAB_SIZE)
    .height(AppDimens.FAB_SIZE)
    .borderRadius(AppDimens.FAB_SIZE / 2)
    .linearGradient({
      direction: GradientDirection.RightBottom,
      colors: [[AppColors.PRIMARY, 0], ['#0056CC', 1]]
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: 12,
      color: 'rgba(0, 122, 255, 0.3)',
      offsetX: 0,
      offsetY: 4
    })
    .position({ x: '80%', y: '90%' })
    .onClick(() => this.showAddModal())
  }

  @Builder
  DrawerOverlay() {
    Stack() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.4)')
        .onClick(() => {
          this.showDrawer = false;
        })

      // 侧边栏
      AppDrawer({
        onDataManagement: () => {
          this.showDrawer = false;
          this.showSettingSheet();
        },
        onDataAnalysis: () => {
          this.showDrawer = false;
        },
        onClose: () => {
          this.showDrawer = false;
        }
      })
        .position({ x: 0, y: 0 })
        .transition(TransitionEffect.translate({ x: -300 }).animation({ duration: 300 }))
    }
    .width('100%')
    .height('100%')
  }

  // ========== 弹窗方法 ==========

  showAddModal() {
    if (this.currentView === 'anchors') {
      this.addAnchorModalController = new CustomDialogController({
        builder: AddAnchorModal({
          onConfirm: (name: string, time: string) => {
            this.viewModel.addAnchor(name, time);
          }
        }),
        alignment: DialogAlignment.Center,
        customStyle: true
      });
      this.addAnchorModalController.open();
    } else {
      this.addModalController = new CustomDialogController({
        builder: AddModal({
          title: this.currentView === 'plans' ? AppStrings.ADD_PLAN_TITLE : AppStrings.ADD_HABIT_TITLE,
          placeholder: this.currentView === 'plans' ? AppStrings.ADD_PLAN_PLACEHOLDER : AppStrings.ADD_HABIT_PLACEHOLDER,
          onConfirm: (text: string) => {
            if (this.currentView === 'plans') {
              this.viewModel.addPlan(text);
            } else {
              this.viewModel.addHabit(text);
            }
          }
        }),
        alignment: DialogAlignment.Center,
        customStyle: true
      });
      this.addModalController.open();
    }
  }

  showEditPlanModal(plan: Plan) {
    this.addModalController = new CustomDialogController({
      builder: AddModal({
        title: AppStrings.EDIT_PLAN_TITLE,
        placeholder: AppStrings.ADD_PLAN_PLACEHOLDER,
        initialValue: plan.name,
        onConfirm: (text: string) => {
          this.viewModel.updatePlan(plan.id, text);
          this.expandedCardId = '';
        }
      }),
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.addModalController.open();
  }

  showEditHabitModal(habit: Habit) {
    this.addModalController = new CustomDialogController({
      builder: AddModal({
        title: AppStrings.EDIT_HABIT_TITLE,
        placeholder: AppStrings.ADD_HABIT_PLACEHOLDER,
        initialValue: habit.name,
        onConfirm: (text: string) => {
          this.viewModel.updateHabit(habit.id, text);
          this.expandedCardId = '';
        }
      }),
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.addModalController.open();
  }

  showEditAnchorModal(anchor: Anchor) {
    this.addAnchorModalController = new CustomDialogController({
      builder: AddAnchorModal({
        initialName: anchor.name,
        initialTime: anchor.time,
        onConfirm: (name: string, time: string) => {
          this.viewModel.updateAnchor(anchor.id, name, time);
        }
      }),
      alignment: DialogAlignment.Center,
      customStyle: true
    });
    this.addAnchorModalController.open();
  }

  triggerSuccess(description: string, type: string) {
    setTimeout(() => {
      this.successPopupController = new CustomDialogController({
        builder: SuccessPopup({
          description: description,
          type: type,
          rainbowFart: this.viewModel.rainbowFart,
          onClose: () => {}
        }),
        alignment: DialogAlignment.Center,
        customStyle: true
      });
      this.successPopupController.open();
    }, 200);
  }

  showSettingSheet() {
    this.settingSheetController = new CustomDialogController({
      builder: SettingSheet({
        exportData: this.viewModel.exportData(),
        onImport: (data: string) => {
          this.viewModel.importData(data);
        }
      }),
      alignment: DialogAlignment.Bottom,
      customStyle: true
    });
    this.settingSheetController.open();
  }
}
