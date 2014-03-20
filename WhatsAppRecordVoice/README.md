WhatsAppRecordVoice
===================
How to:
-------------------


WARVChatPanelView *view = [[WARVChatPanelView alloc] init];
view.delegate = self;
[view showInView:self.view];

implement panelview delegate

- (void)chatPanelViewShouldBeginRecord:(WARVChatPanelView *)view;
- (void)chatPanelViewShouldCancelRecord:(WARVChatPanelView *)view;
- (void)chatPanelViewShouldFinishedRecord:(WARVChatPanelView *)view;
