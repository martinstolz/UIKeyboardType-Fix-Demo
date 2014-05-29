//
//  US2ViewController.m
//  KeyboardType
//
//  Created by Martin Stolz on 28/05/2014.
//  Copyright (c) 2014 ustwo. All rights reserved.
//

#import "US2ViewController.h"
#import <objc/message.h>

@interface US2ViewController () <UITextFieldDelegate>
@property (nonatomic, strong) NSDictionary *mapDictionary;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@end


@implementation US2ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapDictionary = @{
                           @"Capital-Letters": @(UIKeyboardTypeASCIICapable),
                           @"Small-Letters": @(UIKeyboardTypeASCIICapable),
                           @"First-Alternate": @(UIKeyboardTypeASCIICapable),
                           @"Numbers-And-Punctuation": @(UIKeyboardTypeNumbersAndPunctuation),
                           @"Numbers-And-Punctuation-Alternate": @(UIKeyboardTypeNumbersAndPunctuation)
                           };
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 64.0, 300.0, 44.0)];
    self.textField.backgroundColor = [UIColor lightGrayColor];
    self.textField.keyboardType = UIKeyboardTypeASCIICapable;
    self.textField.delegate = self;
    self.textField.spellCheckingType = UITextSpellCheckingTypeYes;
    [self.view addSubview:self.textField];
    
    // Listen for text field changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange) name:UITextFieldTextDidChangeNotification object:self.textField];
}

- (void)textFieldTextDidChange
{
    self.keyboardType = [self determineKeyboardType];
    NSLog(@"textFieldTextDidChange: active keyboard type: %ld", self.keyboardType);
    
    // Override initial keyboard type
    self.textField.keyboardType = self.keyboardType;
    if([self.textField.text isEqualToString:@""])
    {
        self.textField.returnKeyType = UIReturnKeyDefault;
    }
    else
    {
        self.textField.returnKeyType = UIReturnKeySend;
    }
    [self.textField reloadInputViews];
}

- (UIKeyboardType)determineKeyboardType
{
    UIWindow *keyboardWindow = [self keyboardWindow];
    UIView *keyboardView = [self keyboardViewInKeyboardWindow:keyboardWindow];
    NSString *componentName = [self componentNameFromKeyboardView:keyboardView];
    UIKeyboardType keyboardType = [self mapComponentNameToKeyboardType:componentName];
    
    return keyboardType;
}

- (UIWindow *)keyboardWindow
{
    UIWindow *keyboardWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows)
    {
        if (![window.class isEqual:UIWindow.class])
        {
            keyboardWindow = window;
            break;
        }
    }
    
    return keyboardWindow;
}

- (UIView *)keyboardViewInKeyboardWindow:(UIWindow *)keyboardWindow
{
    UIView *foundKeyboard = nil;
    for (UIView *possibleKeyboard in keyboardWindow.subviews)
    {
        Class keyboardClass = NSClassFromString(@"UIPeripheralHostView");
        if ([possibleKeyboard isKindOfClass:keyboardClass])
        {
            foundKeyboard = possibleKeyboard;
            break;
        }
    }
    
    return foundKeyboard;
}

- (NSString *)componentNameFromKeyboardView:(UIView *)keyboardView
{
    NSString *componentName = nil;
    
    id keyplane = nil;
    [self keyboardKeyplaneView:&keyplane inKeyboardView:keyboardView];
    SEL componentNameSelector = NSSelectorFromString(@"componentName");
    componentName = objc_msgSend(keyplane, componentNameSelector);
    
    return componentName;
}

- (void)keyboardKeyplaneView:(id *)keyplaneView inKeyboardView:(UIView *)keyboardView
{
    NSArray *subviews = keyboardView.subviews;
    if (subviews.count == 0)
    {
        return;
    }
    
    for (UIView *subview in subviews)
    {
        if ([NSStringFromClass(subview.class) isEqualToString:@"UIKBKeyplaneView"])
        {
            SEL keyplaneSelector = NSSelectorFromString(@"keyplane");
            if ([subview respondsToSelector:keyplaneSelector])
            {
                NSObject *keyplane = objc_msgSend(subview, keyplaneSelector);
                if (keyplane.class == NSClassFromString(@"UIKBTree"))
                {
                    *keyplaneView = keyplane;
                    return;
                }
            }
        }
        
        [self keyboardKeyplaneView:keyplaneView inKeyboardView:subview];
    }
}

- (UIKeyboardType)mapComponentNameToKeyboardType:(NSString *)componentName
{
    UIKeyboardType keyboardType = 0;
    
    NSNumber *value = [self.mapDictionary valueForKey:componentName];
    if (value)
    {
        keyboardType = [value intValue];
    }
    
    return keyboardType;
}

@end
