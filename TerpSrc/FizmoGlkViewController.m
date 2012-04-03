/* FizmoGlkViewController.m: Fizmo-specific subclass of the IosGlk view controller
 for IosFizmo, an IosGlk port of the Fizmo Z-machine interpreter.
 Designed by Andrew Plotkin <erkyrath@eblong.com>
 http://eblong.com/zarf/glk/
 */

#import "FizmoGlkViewController.h"
#import "FizmoGlkDelegate.h"
#import "IosGlkAppDelegate.h"
#import "GlkFrameView.h"
#import "GlkWinBufferView.h"
#import "NotesViewController.h"
#import "PrefsMenuView.h"

@implementation FizmoGlkViewController

@synthesize notesvc;

+ (FizmoGlkViewController *) singleton {
	return (FizmoGlkViewController *)([IosGlkAppDelegate singleton].glkviewc);
}

- (FizmoGlkDelegate *) fizmoDelegate {
	return (FizmoGlkDelegate *)self.glkdelegate;
}

- (void) didFinishLaunching {
	[super didFinishLaunching];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	CGFloat maxwidth = [defaults floatForKey:@"FrameMaxWidth"];
	self.fizmoDelegate.maxwidth = maxwidth;
	
	/* Font-scale values are arbitrarily between 1 and 5. */
	int fontscale = [defaults integerForKey:@"FontScale"];
	if (fontscale == 0)
		fontscale = 3;
	self.fizmoDelegate.fontscale = fontscale;
	
	/* Color-scheme values are 0 to 2. */
	int colorscheme = [defaults integerForKey:@"ColorScheme"];
	self.fizmoDelegate.colorscheme = colorscheme;
	
	NSString *fontfamily = [defaults stringForKey:@"FontFamily"];
	if (!fontfamily)
		fontfamily = @"Georgia";
	self.fizmoDelegate.fontfamily = fontfamily;
	
	self.navigationController.navigationBar.barStyle = (colorscheme==2 ? UIBarStyleBlack : UIBarStyleDefault);
	
	// Yes, this is in two places.
	self.frameview.backgroundColor = [self.fizmoDelegate genBackgroundColor];
}

- (void) becameInactive {
	[notesvc saveIfNeeded];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.frameview.backgroundColor = [self.fizmoDelegate genBackgroundColor];
	
	if ([frameview respondsToSelector:@selector(addGestureRecognizer:)]) {
		/* gestures are available in iOS 3.2 and up */
		UISwipeGestureRecognizer *recognizer;
		recognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)] autorelease];
		recognizer.direction = UISwipeGestureRecognizerDirectionLeft;
		[frameview addGestureRecognizer:recognizer];
		recognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)] autorelease];
		recognizer.direction = UISwipeGestureRecognizerDirectionRight;
		[frameview addGestureRecognizer:recognizer];
	}
	
	/* Interface Builder currently doesn't allow us to set the voiceover labels for bar button items. We do it in code. */
	UIBarButtonItem *stylebutton = self.navigationItem.leftBarButtonItem;
	if (stylebutton && [stylebutton respondsToSelector:@selector(setAccessibilityLabel:)]) {
		[stylebutton setAccessibilityLabel:@"Text Styles"]; //###localize
	}
	UIBarButtonItem *keyboardbutton = self.navigationItem.rightBarButtonItem;
	if (keyboardbutton && [keyboardbutton respondsToSelector:@selector(setAccessibilityLabel:)]) {
		[keyboardbutton setAccessibilityLabel:@"Compose Command"]; //###localize
	}
}

/* UITabBarController delegate method */
- (void) tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewc {
	if (![viewc isKindOfClass:[UINavigationController class]])
		return;
	UINavigationController *navc = (UINavigationController *)viewc;
	NSArray *viewcstack = navc.viewControllers;
	if (!viewcstack || !viewcstack.count)
		return;
	UIViewController *rootviewc = [viewcstack objectAtIndex:0];
	//NSLog(@"### tabBarController did select %@ (%@)", navc, rootviewc);
	
	if (rootviewc != notesvc) {
		/* If the notesvc was drilled into the transcripts view or subviews, pop out of there. */
		[notesvc.navigationController popToRootViewControllerAnimated:NO];
	}
}

- (IBAction) toggleKeyboard {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		/* Can't have the prefs menu up at the same time as the keyboard -- the iPhone screen is too small. */
		if (frameview.menuview && [frameview.menuview isKindOfClass:[PrefsMenuView class]]) {
			[frameview removePopMenuAnimated:YES];
		}
	}
	[super toggleKeyboard];
}

- (void) keyboardWillBeShown:(NSNotification*)notification {
	[super keyboardWillBeShown:notification];
	NSLog(@"Keyboard will be shown (fizmo)");

	if (notesvc) {
		[notesvc adjustToKeyboardBox];
	}
}

- (void) keyboardWillBeHidden:(NSNotification*)notification {
	[super keyboardWillBeHidden:notification];
	NSLog(@"Keyboard will be hidden (fizmo)");

	if (notesvc) {
		[notesvc adjustToKeyboardBox];
	}
}

- (IBAction) showPreferences {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		/* Can't have the prefs menu up at the same time as the keyboard */
		[self hideKeyboard];
	}
	
	if (frameview.menuview && [frameview.menuview isKindOfClass:[PrefsMenuView class]]) {
		[frameview removePopMenuAnimated:YES];
		return;
	}
	
	CGRect rect = CGRectMake(4, 0, 40, 4);
	PrefsMenuView *menuview = [[[PrefsMenuView alloc] initWithFrame:frameview.bounds buttonFrame:rect belowButton:YES] autorelease];
	[frameview postPopMenu:menuview];
}

- (void) handleSwipeLeft:(UIGestureRecognizer *)recognizer {
	if (self.tabBarController) {
		int count = self.tabBarController.viewControllers.count;
		int val = (self.tabBarController.selectedIndex + 1) % count;
		self.tabBarController.selectedIndex = val;
	}
}

- (void) handleSwipeRight:(UIGestureRecognizer *)recognizer {
	if (self.tabBarController) {
		int count = self.tabBarController.viewControllers.count;
		int val = (self.tabBarController.selectedIndex + count - 1) % count;
		self.tabBarController.selectedIndex = val;
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
	//### should the iPad support horizontal layout?
	return (orientation == UIInterfaceOrientationPortrait);
}

@end
