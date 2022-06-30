#if defined _sr_menu_included
 #endinput
#endif
#define _sr_menu_included

#define MENU_TIME 20
#define RULES_PER_PAGE 5
#define TEXT_BUFFER_MAX_SIZE (256 * 4)

#define MENU_SOUND_OPEN "buttons/button4.wav"
#define MENU_SOUND_ITEM "buttons/button14.wav"
#define MENU_SOUND_EXIT "buttons/combine_button7.wav"

#define CHOICE_BACK 8
#define CHOICE_NEXT 9
#define CHOICE_EXIT 10

enum Page {
    Page_First,
    Page_Previous,
    Page_Next
};
