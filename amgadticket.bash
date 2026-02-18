● Both changes are in place. Here's a summary of what was changed and why:                                                                                                                                                          
                                                                                                                                                                                                                                  
  ---                                                                                                                                                                                                                               
  Changes Made                                                                                                                                                                                                                    
                                                                                                                                                                                                                                    
  1. AbsRVPVRequest.java (line 113) - Domain fix                                                                                                                                                                                  

  Added a guard clause to updateRequestStatusIfNeeded():
  if (ObjectChecker.isNotEmptyOrNull(getUserRequestStatus()) && !getUserRequestStatus().isInitial())
      return;

  Before: When makeRequestStatusAcceptedWithSave is ON, systemRequestStatus was always forced to Accepted, even if the user explicitly set userRequestStatus to Rejected or PostPoned.

  After: The auto-accept only happens when userRequestStatus is null, empty, or Initial. If the user has explicitly set the status to Rejected, PostPoned, or Accepted, their decision is respected and systemRequestStatus is not
  overridden.

  This means:
  - userRequestStatus = Rejected → systemRequestStatus = Rejected → won't show in search
  - userRequestStatus = PostPoned → systemRequestStatus = PostPoned → won't show in search
  - userRequestStatus = Initial or empty → systemRequestStatus = Accepted (auto-accepted as intended)

  2. PaymentVoucherPostActions.java (line 71) - Filter fix

  Added .and().field(NotGeneratedFields.commitedBefore).equal("true") to the PVRequest/ConsolidatedPVRequest filter.

  This ensures documents that are still in the approval workflow (not yet committed) don't appear in the from-doc search. This follows the same pattern used in CPAProjExpenseDocPostActions and MultiMobDeliveryDocPostActions.

✻ Cogitated for 12m 2s                                                                                                                                                                                                              
   
❯ ممكن تفهمني اللي انت عملته بالعربي ببساطة                                                                                                                                                                                         
                                                                                                                                                                                                                                  
● ملخص التغييرات                                                                                                                                                                                                                    
                                                                                                                                                                                                                                    
  المشكلة                                                                                                                                                                                                                           
                                                                           
  لما اوبشن "جعل حالة الطلب قبول مع الحفظ" يكون مفعّل في توجيه طلب الصرف، النظام كان يجبر systemRequestStatus = Accepted لكل الطلبات بدون استثناء.                                                                                  
                                                                                                                                                                                                                                    
  يعني حتى لو المستخدم رفض الطلب يدوياً (userRequestStatus = Rejected)، النظام يرجع يغيرها لمقبولة. وبالتالي لما تفتح سند صرف وتختار "بناءاً على طلب صرف"، كل الطلبات تطلع - حتى المرفوضة واللي لسه بانتظار الموافقة.

  التعديل الأول - AbsRVPVRequest.java

  الكود القديم:
  // كان يخلي الحالة "مقبول" دايماً بدون أي شرط
  setSystemRequestStatus(RVPVReqStatus.Accepted());

  الكود الجديد:
  // لو المستخدم حدد حالة غير "مبدئي" (يعني رفض أو تأجيل) → لا تتدخل
  if (ObjectChecker.isNotEmptyOrNull(getUserRequestStatus()) && !getUserRequestStatus().isInitial())
      return;
  setSystemRequestStatus(RVPVReqStatus.Accepted());

  يعني الآن القبول التلقائي يشتغل فقط لو المستخدم ما حدد حالة، أو حالة الطلب "مبدئي". لو المستخدم رفض الطلب أو أجّله، النظام يحترم قراره وما يغيره.

  التعديل الثاني - PaymentVoucherPostActions.java

  أضفت شرط .field(NotGeneratedFields.commitedBefore).equal("true") على فلتر البحث.

  يعني لما تبحث عن طلبات صرف من سند الصرف، ما يطلع إلا الطلبات المعتمدة فعلاً (اللي اتحفظت واتنفذت). الطلبات اللي لسه في دورة الموافقة ما تطلعش.