import UIKit

class MultiViewController: UIViewController, UITextFieldDelegate {
	
	let model = Model(value: "initial value")
	
	@IBOutlet var mvcTextField: UITextField!
	@IBOutlet var mvpTextField: UITextField!
	@IBOutlet var mvvmmTextField: UITextField!
	@IBOutlet var mvvmTextField: UITextField!
	@IBOutlet var mvcvsTextField: UITextField!

	
	@IBOutlet var mvcButton: UIButton!
	@IBOutlet var mvpButton: UIButton!
	@IBOutlet var mvvmmButton: UIButton!
	@IBOutlet var mvvmButton: UIButton!
	@IBOutlet var mvcvsButton: UIButton!

	@IBOutlet var stackView: UIStackView!
	
    // Strong references
	var mvcObserver: NSObjectProtocol?
    
	var presenter: ViewPresenter?
	
	var minimalViewModel: MinimalViewModel?
	var minimalObserver: NSObjectProtocol?
	
	var viewModel: ViewModel?
	var mvvmObserver: Cancellable?
	
	var viewState: ViewState?
	var viewStateModelObserver: NSObjectProtocol?
	var viewStateObserver: NSObjectProtocol?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		mvcDidLoad()
		mvpDidLoad()
		mvvmMinimalDidLoad()
		mvvmDidLoad()
		mvcvsDidLoad()
	}
}


// MVC ---------------------------------------------------------

extension MultiViewController {
	func mvcDidLoad() {
		mvcTextField.text = model.value
		mvcObserver = NotificationCenter.default.addObserver(forName: Model.textDidChange, object: nil, queue: nil) { [mvcTextField] (note) in
			mvcTextField?.text = note.userInfo?[Model.textKey] as? String
		}
	}
	
	@IBAction func mvcButtonPressed() {
		model.value = mvcTextField?.text ?? ""
	}
}


// MVP ---------------------------------------------------------

protocol ViewProtocol: class {
	var textFieldValue: String { get set }
}

class ViewPresenter {
	let model: Model
	weak var view: ViewProtocol?
	let observer: NSObjectProtocol
    
	init(model: Model, view: ViewProtocol) {
		self.model = model //改变的
		self.view = view  //当前的
		
		view.textFieldValue = model.value
        
		observer = NotificationCenter.default.addObserver(forName: Model.textDidChange, object: nil, queue: nil) { [view] (note) in
            //当前的 = 改变的
			view.textFieldValue = note.userInfo?[Model.textKey] as? String ?? ""
		}
	}
	
	func commit() {
		model.value = view?.textFieldValue ?? ""
	}
}

extension MultiViewController: ViewProtocol {
	func mvpDidLoad() {
		presenter = ViewPresenter(model: model, view: self)
	}
	
	var textFieldValue: String {
		get {
			return mvpTextField.text ?? ""
		}
		set {
			mvpTextField.text = newValue
		}
	}
	
	@IBAction func mvpButtonPressed() {
		presenter?.commit()
	}
}


// Minimal MVVM ---------------------------------------------------------

class MinimalViewModel: NSObject {
	let model: Model
	var observer: NSObjectProtocol?
	@objc dynamic var textFieldValue: String
	
	init(model: Model) {
		self.model = model
		textFieldValue = model.value
		super.init()
		observer = NotificationCenter.default.addObserver(forName: Model.textDidChange, object: nil, queue: nil) { [weak self] (note) in
			self?.textFieldValue = note.userInfo?[Model.textKey] as? String ?? ""
		}
		
	}
	
	func commit(value: String) {
		model.value = value
	}
}

extension MultiViewController {
	func mvvmMinimalDidLoad() {
		minimalViewModel = MinimalViewModel(model: model)
		minimalObserver = minimalViewModel?.observe(\.textFieldValue, options: [.initial, .new], changeHandler: { [weak self] (_, change) in
			self?.mvvmmTextField.text = change.newValue
		})
	}
	
	@IBAction func mvvmmButtonPressed() {
		minimalViewModel?.commit(value: mvvmmTextField.text ?? "")
	}
}


// MVVM -------------   --------------------------------------------

class ViewModel {
	let model: Model
    
    var textFieldValue: Signal<String> {
        return Signal
            .notifications(name: Model.textDidChange)
            .compactMap { note in note.userInfo?[Model.textKey] as? String }
            .continuous(initialValue: model.value)
    }
    
	init(model: Model) {
		self.model = model
	}
    
	func commit(value: String) {
		model.value = value
	}
}

extension MultiViewController {
	func mvvmDidLoad() {
		viewModel = ViewModel(model: model)
		mvvmObserver = viewModel!.textFieldValue
			.subscribeValues { [unowned self] (str) in self.mvvmTextField.text = str }
	}
    
	@IBAction func mvvmButtonPressed() {
		viewModel?.commit(value: self.mvvmTextField.text ?? "")
	}
}


// MVC+VS ---------------------------------------------------------

class ViewState {
	var textFieldValue: String = ""
	
	init(textFieldValue: String) {
		self.textFieldValue = textFieldValue
	}
}

extension MultiViewController {
	func mvcvsDidLoad() {
		viewState = ViewState(textFieldValue: model.value)
		mvcvsTextField.text = model.value
		viewStateObserver = NotificationCenter.default.addObserver(forName: .UITextFieldTextDidChange, object: mvcvsTextField, queue: nil, using: { [viewState] n in
			viewState?.textFieldValue = (n.object as! UITextField).text ?? ""
		})
		viewStateModelObserver = NotificationCenter.default.addObserver(forName: Model.textDidChange, object: nil, queue: nil, using: { [mvcvsTextField] n in
			mvcvsTextField?.text = n.userInfo?[Model.textKey] as? String
		})
	}
	
	@IBAction func mvcvsButtonPressed() {
		model.value = viewState?.textFieldValue ?? ""
	}
}


