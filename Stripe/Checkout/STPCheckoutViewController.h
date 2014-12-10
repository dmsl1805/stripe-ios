//
//  STPCheckoutViewController.h
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//

#import <UIKit/UIKit.h>
#import "STPCheckoutProtocols.h"

@class STPCheckoutOptions, STPToken;
@protocol STPCheckoutViewControllerDelegate;

/**
 Controls a UIWebView that loads an iOS-optimized version of Stripe Checkout. You can present it modally or push it onto a UINavigationController stack. Note
 that if you're using an STPPaymentPresenter to collect your user's payment details (highly recommended), you do not have to use this class directly.
 */
@interface STPCheckoutViewController : UIViewController

/**
 *  Creates an STPCheckoutViewController with the desired options. The options are copied at this step, so changing any of their values after instantiating an
 *STPCheckoutViewController will have no effect.
 *
 *  @param options A configuration object that describes how to display Stripe Checkout.
 *
 */
- (instancetype)initWithOptions:(STPCheckoutOptions *)options NS_DESIGNATED_INITIALIZER;
@property (nonatomic, readonly, copy) STPCheckoutOptions *options;

/**
 *  Note: you must set a delegate before showing an STPViewController.
 */
@property (nonatomic, weak) id<STPCheckoutViewControllerDelegate> delegate;

@end

@protocol STPCheckoutViewControllerDelegate<NSObject>

/**
 *  Called when the user taps the cancel button inside the Checkout web view.
 *
 *  @param controller the controller that was canceled.
 */
- (void)checkoutControllerDidCancel:(STPCheckoutViewController *)controller;

/**
 *  Called when the checkout view controller has finished displaying the "success" or "error" animation. At this point, the controller is done with its work.
 *You should dismiss the view controller at this point, probably by calling `dismissViewControllerAnimated:completion:`.
 *
 *  @param controller the controller that has finished.
 */
- (void)checkoutControllerDidFinish:(STPCheckoutViewController *)controller;

/**
 *  After the user has provided valid credit card information and pressed the "pay" button, Checkout will communicate with Stripe and obtain a tokenized version
 of their credit card.

    At this point, you should submit this token to your backend, which should use this token to create a charge. For more information on this, see
 // The delegate must call completion with an appropriate authorization status, as may be determined
 // by submitting the payment credential to a processing gateway for payment authorization.
 *
 *  @param controller <#controller description#>
 *  @param token      <#token description#>
 *  @param completion <#completion description#>
 */
- (void)checkoutController:(STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion;
- (void)checkoutController:(STPCheckoutViewController *)controller didFailWithError:(NSError *)error;

@end