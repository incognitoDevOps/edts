from content.models import FAQ

class FAQService:
    @staticmethod
    def get_all_faqs():
        # Return FAQs ordered by creation date (latest first)
        return FAQ.objects.all().order_by('-created_on')
    
    @staticmethod
    def get_faq_by_id(faq_id):
        try:
            return FAQ.objects.get(id=faq_id)
        except FAQ.DoesNotExist:
            return None

    @staticmethod
    def create_faq(question, answer):
        faq = FAQ(question=question, answer=answer)
        faq.save()
        return faq

    @staticmethod
    def update_faq(faq_id, question=None, answer=None):
        faq = FAQService.get_faq_by_id(faq_id)
        if faq:
            if question is not None:
                faq.question = question
            if answer is not None:
                faq.answer = answer
            faq.save()
        return faq

    @staticmethod
    def delete_faq(faq_id):
        faq = FAQService.get_faq_by_id(faq_id)
        if faq:
            faq.delete()
            return True
        return False
