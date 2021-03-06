//
//  STPPaymentCardTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Stripe.h"
#import "STPPaymentCardTextFieldViewModel.h"
#import "STPFormTextField.h"
#import "STPImageLibrary.h"
#import "STPWeakStrongMacros.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPPaymentCardTextField()<STPFormTextFieldDelegate>

@property(nonatomic, readwrite, strong)STPFormTextField *sizingField;

@property(nonatomic, readwrite, weak)UIImageView *brandImageView;
@property(nonatomic, readwrite, weak)UIView *fieldsView;

@property(nonatomic, readwrite, strong)STPPaymentCardTextFieldViewModel *viewModel;

@property(nonatomic, readonly, weak)UITextField *currentFirstResponderField;

@property(nonatomic, assign)BOOL numberFieldShrunk;

@property(nonatomic, readwrite, strong)STPCardParams *internalCardParams;

@end

@implementation STPPaymentCardTextField

@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize textErrorColor = _textErrorColor;
@synthesize placeholderColor = _placeholderColor;
@dynamic enabled;

CGFloat const STPPaymentCardTextFieldDefaultPadding = 13;

#if CGFLOAT_IS_DOUBLE
#define stp_roundCGFloat(x) round(x)
#else
#define stp_roundCGFloat(x) roundf(x)
#endif

#pragma mark initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    
    self.borderColor = [self.class placeholderGrayColor];
    self.cornerRadius = 5.0f;
    self.borderWidth = 1.0f;
    
    self.clipsToBounds = YES;
    
    _internalCardParams = [STPCardParams new];
    _viewModel = [STPPaymentCardTextFieldViewModel new];
    _sizingField = [self buildTextField];
    _sizingField.formDelegate = nil;
    
    UIImageView *brandImageView = [[UIImageView alloc] initWithImage:self.brandImage];
    brandImageView.contentMode = UIViewContentModeCenter;
    brandImageView.backgroundColor = [UIColor clearColor];
    if ([brandImageView respondsToSelector:@selector(setTintColor:)]) {
        brandImageView.tintColor = self.placeholderColor;
    }
    self.brandImageView = brandImageView;
    
    STPFormTextField *numberField = [self buildTextField];
    numberField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorCardNumbers;
    numberField.tag = STPCardFieldTypeNumber;
    numberField.accessibilityLabel = NSLocalizedString(@"card number", @"accessibility label for text field");
    numberField.textAlignment = NSTextAlignmentCenter;
    self.numberField = numberField;
    self.numberPlaceholder = [self.viewModel defaultPlaceholder];
    
    STPFormTextField *expirationField = [self buildTextField];
    expirationField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorExpiration;
    expirationField.tag = STPCardFieldTypeExpiration;
    expirationField.accessibilityLabel = NSLocalizedString(@"expiration date", @"accessibility label for text field");
    expirationField.textAlignment = NSTextAlignmentCenter;
    self.expirationField = expirationField;
    self.expirationPlaceholder = @"MM/YY";

    STPFormTextField *cvcField = [self buildTextField];
    cvcField.tag = STPCardFieldTypeCVC;
    cvcField.textAlignment = NSTextAlignmentCenter;

    self.cvcField = cvcField;
    self.cvcPlaceholder = @"CVC";

    
    UIView *fieldsView = [[UIView alloc] init];
    fieldsView.clipsToBounds = YES;
    fieldsView.backgroundColor = [UIColor clearColor];
    self.fieldsView = fieldsView;
    
    [self addSubview:self.fieldsView];
    [self.fieldsView addSubview:cvcField];
    [self.fieldsView addSubview:expirationField];
    [self.fieldsView addSubview:numberField];
    [self addSubview:brandImageView];
}

- (void)updateTextFields {
    self.numberField.text = self.numberText;
    if ( self.numberPlaceholderAttributed ) {
        self.numberField.attributedPlaceholder = self.numberPlaceholderAttributed;
    }
    self.cvcField.text = self.cvcText;
    self.cvcField.accessibilityLabel = self.cvcPlaceholder;
    if ( self.cvcPlaceholderAttributed ) {
        self.cvcField.attributedPlaceholder = self.cvcPlaceholderAttributed;
    }
    self.expirationField.text = self.expirationText;
    if ( self.expirationPlaceholderAttributed ) {
        self.expirationField.attributedPlaceholder = self.expirationPlaceholderAttributed;
    }
}

- (STPPaymentCardTextFieldViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [STPPaymentCardTextFieldViewModel new];
    }
    return _viewModel;
}

#pragma mark appearance properties

+ (UIColor *)placeholderGrayColor {
    return [UIColor lightGrayColor];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[backgroundColor copy]];
    self.numberField.backgroundColor = self.backgroundColor;
}

- (UIColor *)backgroundColor {
    return [super backgroundColor] ?: [UIColor whiteColor];
}

- (void)setFont:(UIFont *)font {
    _font = [font copy];
    
    for (UITextField *field in [self allFields]) {
        field.font = _font;
    }
    
    self.sizingField.font = _font;
    
    [self setNeedsLayout];
}

- (UIFont *)font {
    return _font ?: [UIFont systemFontOfSize:18];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = [textColor copy];
    
    for (STPFormTextField *field in [self allFields]) {
        field.defaultColor = _textColor;
    }
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];
    for (UITextField *field in [self allFields]) {
        field.contentVerticalAlignment = contentVerticalAlignment;
    }
    switch (contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter:
            self.brandImageView.contentMode = UIViewContentModeCenter;
            break;
        case UIControlContentVerticalAlignmentBottom:
            self.brandImageView.contentMode = UIViewContentModeBottom;
            break;
        case UIControlContentVerticalAlignmentFill:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
        case UIControlContentVerticalAlignmentTop:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
    }
}

- (UIColor *)textColor {
    return _textColor ?: [UIColor blackColor];
}

- (void)setTextErrorColor:(UIColor *)textErrorColor {
    _textErrorColor = [textErrorColor copy];
    
    for (STPFormTextField *field in [self allFields]) {
        field.errorColor = _textErrorColor;
    }
}

- (UIColor *)textErrorColor {
    return _textErrorColor ?: [UIColor redColor];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = [placeholderColor copy];
    
    if ([self.brandImageView respondsToSelector:@selector(setTintColor:)]) {
        self.brandImageView.tintColor = placeholderColor;
    }
    
    for (STPFormTextField *field in [self allFields]) {
        field.placeholderColor = _placeholderColor;
    }
}

- (UIColor *)placeholderColor {
    return _placeholderColor ?: [self.class placeholderGrayColor];
}

- (void)setNumberPlaceholder:(NSString * __nullable)numberPlaceholder {
    _numberPlaceholder = [numberPlaceholder copy];
    self.numberField.placeholder = _numberPlaceholder;
}

- (void)setExpirationPlaceholder:(NSString * __nullable)expirationPlaceholder {
    _expirationPlaceholder = [expirationPlaceholder copy];
    self.expirationField.placeholder = _expirationPlaceholder;
}

- (void)setCvcPlaceholder:(NSString * __nullable)cvcPlaceholder {
    _cvcPlaceholder = [cvcPlaceholder copy];
    self.cvcField.placeholder = _cvcPlaceholder;
}

- (void)setCursorColor:(UIColor *)cursorColor {
    self.tintColor = cursorColor;
}

- (UIColor *)cursorColor {
    return self.tintColor;
}

- (void)setBorderColor:(UIColor * __nullable)borderColor {
    self.layer.borderColor = [[borderColor copy] CGColor];
}

- (UIColor * __nullable)borderColor {
    return [[UIColor alloc] initWithCGColor:self.layer.borderColor];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    _keyboardAppearance = keyboardAppearance;
    for (STPFormTextField *field in [self allFields]) {
        field.keyboardAppearance = keyboardAppearance;
    }
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;
    
    for (STPFormTextField *field in [self allFields]) {
        field.inputAccessoryView = inputAccessoryView;
    }
}

#pragma mark UIControl

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    for (STPFormTextField *textField in [self allFields]) {
        textField.enabled = enabled;
    };
}

#pragma mark UIResponder & related methods

- (BOOL)isFirstResponder {
    return [self.currentFirstResponderField isFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return [[self nextFirstResponderField] canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [[self nextFirstResponderField] becomeFirstResponder];
}

- (STPFormTextField *)nextFirstResponderField {
    if ([self.viewModel validationStateForField:STPCardFieldTypeNumber] != STPCardValidationStateValid) {
        return self.numberField;
    } else if ([self.viewModel validationStateForField:STPCardFieldTypeExpiration] != STPCardValidationStateValid) {
        return self.expirationField;
    } else {
        return self.cvcField;
    }
}

- (STPFormTextField *)currentFirstResponderField {
    for (STPFormTextField *textField in [self allFields]) {
        if ([textField isFirstResponder]) {
            return textField;
        }
    }
    return nil;
}

- (BOOL)canResignFirstResponder {
    return [self.currentFirstResponderField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    BOOL success = [self.currentFirstResponderField resignFirstResponder];
    [self updateImageForFieldType:STPCardFieldTypeNumber];
    return success;
}

- (STPFormTextField *)previousField {
    if (self.currentFirstResponderField == self.cvcField) {
        return self.expirationField;
    } else if (self.currentFirstResponderField == self.expirationField) {
        return self.numberField;
    }
    return nil;
}

#pragma mark public convenience methods

- (void)clear {
    for (STPFormTextField *field in [self allFields]) {
        field.text = @"";
    }
    self.viewModel = [STPPaymentCardTextFieldViewModel new];
    [self onChange];
    [self updateImageForFieldType:STPCardFieldTypeNumber];
    
}

- (BOOL)isValid {
    return [self.viewModel isValid];
}

- (BOOL)valid {
    return self.isValid;
}

#pragma mark readonly variables

- (NSString *)cardNumber {
    return self.viewModel.cardNumber;
}

- (NSUInteger)expirationMonth {
    return [self.viewModel.expirationMonth integerValue];
}

- (NSUInteger)expirationYear {
    return [self.viewModel.expirationYear integerValue];
}

- (NSString *)formattedExpirationMonth {
    return self.viewModel.expirationMonth;
}

- (NSString *)formattedExpirationYear {
    return self.viewModel.expirationYear;
}

- (NSString *)cvc {
    return self.viewModel.cvc;
}

- (STPCardParams *)cardParams {
    self.internalCardParams.number = self.cardNumber;
    self.internalCardParams.expMonth = self.expirationMonth;
    self.internalCardParams.expYear = self.expirationYear;
    self.internalCardParams.cvc = self.cvc;
    return self.internalCardParams;
}

- (void)setCardParams:(STPCardParams *)cardParams {
    self.internalCardParams = cardParams;
    [self setText:cardParams.number inField:STPCardFieldTypeNumber];
    BOOL expirationPresent = cardParams.expMonth && cardParams.expYear;
    if (expirationPresent) {
        NSString *text = [NSString stringWithFormat:@"%02lu%02lu",
                          (unsigned long)cardParams.expMonth,
                          (unsigned long)cardParams.expYear%100];
        [self setText:text inField:STPCardFieldTypeExpiration];
    }
    else {
        [self setText:@"" inField:STPCardFieldTypeExpiration];
    }
    [self setText:cardParams.cvc inField:STPCardFieldTypeCVC];
    
    if ([self isFirstResponder]) {
        [[self nextFirstResponderField] becomeFirstResponder];
    }
    
    // update the card image, falling back to the number field image if not editing
    if ([self.expirationField isFirstResponder]) {
        [self updateImageForFieldType:STPCardFieldTypeExpiration];
    }
    else if ([self.cvcField isFirstResponder]) {
        [self updateImageForFieldType:STPCardFieldTypeCVC];
    }
    else {
        [self updateImageForFieldType:STPCardFieldTypeNumber];
    }
}

- (STPCardParams *)card {
    if (!self.isValid) { return nil; }
    return self.cardParams;
}

- (void)setCard:(STPCardParams *)card {
    [self setCardParams:card];
}

- (void)setText:(NSString *)text inField:(STPCardFieldType)field {
    NSString *nonNilText = text ?: @"";
    STPFormTextField *textField = nil;
    switch (field) {
        case STPCardFieldTypeNumber:
            textField = self.numberField;
            break;
        case STPCardFieldTypeExpiration:
            textField = self.expirationField;
            break;
        case STPCardFieldTypeCVC:
            textField = self.cvcField;
            break;
    }
    textField.text = nonNilText;
}

- (CGSize)intrinsicContentSize {
    
    CGSize imageSize = self.brandImage.size;
    
    self.sizingField.text = self.viewModel.defaultPlaceholder;
    CGFloat textHeight = [self.sizingField measureTextSize].height;
    CGFloat imageHeight = imageSize.height + (STPPaymentCardTextFieldDefaultPadding);
    CGFloat height = stp_roundCGFloat((MAX(MAX(imageHeight, textHeight), 44)));
    
    CGFloat width = stp_roundCGFloat([self widthForCardNumber:self.viewModel.defaultPlaceholder] + imageSize.width + (STPPaymentCardTextFieldDefaultPadding * 3));
    
    return CGSizeMake(width, height);
}

- (CGRect)brandImageRectForBounds:(CGRect)bounds {
    return CGRectMake(CGRectGetMidX(bounds) - CGRectGetMidX(bounds) / 2 - self.brandImageView.image.size.width, 0, self.brandImageView.image.size.width, 50);
}

- (CGRect)brandImageRect {
    return CGRectMake(0, 0, self.brandImageView.image.size.width, 50);
}

- (CGRect)fieldsRectForBounds:(CGRect)bounds {
    CGRect brandImageRect = [self brandImageRect];
    return CGRectMake(CGRectGetMaxX(brandImageRect), 0, CGRectGetWidth(bounds) - CGRectGetMaxX(brandImageRect), CGRectGetHeight(bounds));
}

- (CGRect)numberFieldRectForBounds:(CGRect)bounds {
    CGFloat imageWidth = self.brandImageView.bounds.size.width;
    CGFloat numberFieldWidth = bounds.size.width - imageWidth - STPPaymentCardTextFieldDefaultPadding - 45;
    return CGRectMake(STPPaymentCardTextFieldDefaultPadding, 0, numberFieldWidth, 50);
}

- (CGRect)cvcFieldRectForBounds:(CGRect)bounds {
    CGFloat cvcWidth = (bounds.size.width - ( bounds.size.width - self.numberField.bounds.size.width + 20 )) / 2;
    return CGRectMake(STPPaymentCardTextFieldDefaultPadding + 20 + self.expirationField.bounds.size.width, bounds.size.height - 150 / 2, cvcWidth, 50);
}

- (CGRect)expirationFieldRectForBounds:(CGRect)bounds {
    CGFloat expirationWidth = (bounds.size.width - ( bounds.size.width - self.numberField.bounds.size.width + 20 )) / 2;
    return CGRectMake(STPPaymentCardTextFieldDefaultPadding, bounds.size.height - 150 / 2, expirationWidth, 50);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    
    self.brandImageView.frame = [self brandImageRect];
    self.fieldsView.frame = [self fieldsRectForBounds:bounds];
    self.numberField.frame = [self numberFieldRectForBounds:bounds];
    self.expirationField.frame = [self expirationFieldRectForBounds:bounds];
    self.cvcField.frame = [self cvcFieldRectForBounds:bounds];
}

#pragma mark - private helper methods

- (STPFormTextField *)buildTextField {
    STPFormTextField *textField = [[STPFormTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor clearColor];
    textField.keyboardType = UIKeyboardTypePhonePad;
    textField.font = self.font;
    textField.defaultColor = self.textColor;
    textField.errorColor = self.textErrorColor;
    textField.placeholderColor = self.placeholderColor;
    textField.formDelegate = self;
    textField.validText = true;
    return textField;
}

- (NSArray *)allFields {
    NSMutableArray *mutable = [NSMutableArray array];
    if (self.numberField) {
        [mutable addObject:self.numberField];
    }
    if (self.expirationField) {
        [mutable addObject:self.expirationField];
    }
    if (self.cvcField) {
        [mutable addObject:self.cvcField];
    }
    return [mutable copy];
}

typedef void (^STPNumberShrunkCompletionBlock)(BOOL completed);

- (BOOL)shouldShrinkNumberField {
    return [self.viewModel validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid;
}

- (CGFloat)widthForText:(NSString *)text {
    self.sizingField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
    [self.sizingField setText:text];
    return [self.sizingField measureTextSize].width + 8;
}

- (CGFloat)widthForCardNumber:(NSString *)cardNumber {
    self.sizingField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorCardNumbers;
    [self.sizingField setText:cardNumber];
    return [self.sizingField measureTextSize].width + 20;
}

#pragma mark STPFormTextFieldDelegate

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    STPFormTextField *previous = [self previousField];
    [previous becomeFirstResponder];
    [previous deleteBackward];
}

- (NSAttributedString *)formTextField:(STPFormTextField *)formTextField
             modifyIncomingTextChange:(NSAttributedString *)input {
    STPCardFieldType fieldType = formTextField.tag;
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            self.viewModel.cardNumber = input.string;
            break;
        case STPCardFieldTypeExpiration: {
            self.viewModel.rawExpiration = input.string;
            break;
        }
        case STPCardFieldTypeCVC:
            self.viewModel.cvc = input.string;
            break;
    }
    
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            return [[NSAttributedString alloc] initWithString:self.viewModel.cardNumber
                                                   attributes:self.numberField.defaultTextAttributes];
        case STPCardFieldTypeExpiration:
            return [[NSAttributedString alloc] initWithString:self.viewModel.rawExpiration
                                                   attributes:self.expirationField.defaultTextAttributes];
        case STPCardFieldTypeCVC:
            return [[NSAttributedString alloc] initWithString:self.viewModel.cvc
                                                   attributes:self.cvcField.defaultTextAttributes];
    }
}

- (void)formTextFieldTextDidChange:(STPFormTextField *)formTextField {
    STPCardFieldType fieldType = formTextField.tag;
    if (fieldType == STPCardFieldTypeNumber) {
        [self updateImageForFieldType:fieldType];
    }
    
    STPCardValidationState state = [self.viewModel validationStateForField:fieldType];
    formTextField.validText = YES;
    switch (state) {
        case STPCardValidationStateInvalid:
            formTextField.validText = NO;
            break;
        case STPCardValidationStateIncomplete:
            break;
        case STPCardValidationStateValid: {
            [[self nextFirstResponderField] becomeFirstResponder];
            break;
        }
    }
    
    [self onChange];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    switch ((STPCardFieldType)textField.tag) {
        case STPCardFieldTypeNumber:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingNumber:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingNumber:self];
            }
            break;
        case STPCardFieldTypeCVC:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingCVC:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingCVC:self];
            }
            break;
        case STPCardFieldTypeExpiration:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingExpiration:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingExpiration:self];
            }
            break;
    }
    [self updateImageForFieldType:textField.tag];
}

- (BOOL)textFieldShouldEndEditing:(__unused UITextField *)textField {
    [self updateImageForFieldType:STPCardFieldTypeNumber];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch ((STPCardFieldType)textField.tag) {
        case STPCardFieldTypeNumber:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditingNumber:)]) {
                [self.delegate paymentCardTextFieldDidEndEditingNumber:self];
            }
            break;
        case STPCardFieldTypeCVC:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditingCVC:)]) {
                [self.delegate paymentCardTextFieldDidEndEditingCVC:self];
            }
            break;
        case STPCardFieldTypeExpiration:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditingExpiration:)]) {
                [self.delegate paymentCardTextFieldDidEndEditingExpiration:self];
            }
            break;
    }
}

- (UIImage *)brandImage {
    if (self.currentFirstResponderField) {
        return [self brandImageForFieldType:self.currentFirstResponderField.tag];
    } else {
        return [self brandImageForFieldType:STPCardFieldTypeNumber];
    }
}

+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)cardBrand {
    return [STPImageLibrary cvcImageForCardBrand:cardBrand];
}

+ (UIImage *)brandImageForCardBrand:(STPCardBrand)cardBrand {
    return [STPImageLibrary brandImageForCardBrand:cardBrand];
}

- (UIImage *)brandImageForFieldType:(STPCardFieldType)fieldType {
    if (fieldType == STPCardFieldTypeCVC) {
        return [self.class cvcImageForCardBrand:self.viewModel.brand];
    }
    
    return [self.class brandImageForCardBrand:self.viewModel.brand];
}

- (void)updateImageForFieldType:(STPCardFieldType)fieldType {
    UIImage *image = [self brandImageForFieldType:fieldType];
    if (image != self.brandImageView.image) {
        self.brandImageView.image = image;
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        
        [self.brandImageView.layer addAnimation:transition forKey:nil];
        
        [self setNeedsLayout];
    }
}

- (void)onChange {
    if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidChange:)]) {
        [self.delegate paymentCardTextFieldDidChange:self];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark UIKeyInput

- (BOOL)hasText {
    return self.numberField.hasText || self.expirationField.hasText || self.cvcField.hasText;
}

- (void)insertText:(NSString *)text {
    [self.currentFirstResponderField insertText:text];
}

- (void)deleteBackward {
    [self.currentFirstResponderField deleteBackward];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

@implementation PTKCard
@end

@interface PTKView()
@property(nonatomic, weak)id<PTKViewDelegate>internalDelegate;
@end

@implementation PTKView

@dynamic delegate, card;

- (void)setDelegate:(id<PTKViewDelegate> __nullable)delegate {
    self.internalDelegate = delegate;
}

- (id<PTKViewDelegate> __nullable)delegate {
    return self.internalDelegate;
}

- (void)onChange {
    [super onChange];
    [self.internalDelegate paymentView:self withCard:[self card] isValid:self.isValid];
}

- (PTKCard * __nonnull)card {
    PTKCard *card = [[PTKCard alloc] init];
    card.number = self.cardNumber;
    card.expMonth = self.expirationMonth;
    card.expYear = self.expirationYear;
    card.cvc = self.cvc;
    return card;
}

@end

#pragma clang diagnostic pop
