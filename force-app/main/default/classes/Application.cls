public class Application {
  // Configure and create the UnitOfWorkFactory for this Application (UserMode DML for FLS)
	public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
		new UserModeUnitOfWorkFactory(
      new List<SObjectType> {
        Bread_Order__c.SObjectType
      }
    );

	// Configure and create the ServiceFactory for this Application
	// public static final fflib_Application.ServiceFactory Service = 
	// 	new fflib_Application.ServiceFactory( 
	// 		new Map<Type, Type> {
	// 			IBreadOrdersService.class => BreadOrdersServiceImpl.class
  //     }
  //   );

	// Configure and create the SelectorFactory for this Application
	public static final fflib_Application.SelectorFactory Selector = 
		new fflib_Application.SelectorFactory(
			new Map<SObjectType, Type> {
				Bread_Order__c.SObjectType => BreadOrderSelector.class
      }
    );

	// Configure and create the DomainFactory for this Application
	public static final fflib_Application.DomainFactory Domain = 
		new fflib_Application.DomainFactory(
			Application.Selector,
			new Map<SObjectType, Type> {
				Bread_Order__c.SObjectType => BreadOrders.Constructor.class
			}
    );

	// Custom UnitOfWork factory that uses UserModeDML for FLS enforcement
	private class UserModeUnitOfWorkFactory extends fflib_Application.UnitOfWorkFactory {
		public UserModeUnitOfWorkFactory(List<SObjectType> objectTypes) { super(objectTypes); }
		public override fflib_ISObjectUnitOfWork newInstance() {
			if (m_mockUow != null) return m_mockUow;
			return new fflib_SObjectUnitOfWork(m_objectTypes, new fflib_SObjectUnitOfWork.UserModeDML());
		}
	}
}
